const crypto = require('crypto');
const { sequelize, Customer, Product, OrderRecord, OrderItem, Address } = require('../models');
const razorpay = require('../config/razorpay');
const { formatAddress } = require('../dto/orderDto');

const CURRENCY = 'INR';

// Razorpay rejects orders below ₹1.
const MIN_AMOUNT_PAISE = 100;

const NOT_CONFIGURED = {
  error: 'Payment gateway not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.',
  status: 503,
};

/** Receipt has to fit Razorpay's 40-char limit. */
function generateOrderNumber() {
  const stamp = Date.now().toString(36).toUpperCase();
  const suffix = crypto.randomBytes(3).toString('hex').toUpperCase();
  return `NZ-${stamp}-${suffix}`;
}

/** Price a single unit after the product's own discount, in paise. */
function unitPricePaise(product) {
  const discountPercent = product.discountPercent || 0;
  return Math.round(product.priceInPaise * (1 - discountPercent / 100));
}

/** Razorpay caps each note value at 256 characters. */
function sanitizeNotes(notes) {
  const sanitized = {};
  for (const [key, value] of Object.entries(notes || {})) {
    if (value === null || value === undefined) continue;
    const text = String(value).trim();
    if (text) sanitized[key] = text.slice(0, 256);
  }
  return sanitized;
}

function signaturesMatch(expected, received) {
  const a = Buffer.from(expected, 'utf8');
  const b = Buffer.from(String(received || ''), 'utf8');
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

const paymentService = {
  /** Public checkout config for the app. Contains no secret. */
  getConfig() {
    if (!razorpay.isConfigured()) return NOT_CONFIGURED;
    return { keyId: razorpay.getKeyId(), currency: CURRENCY };
  },

  /**
   * Creates a PENDING order priced from the database, then opens a matching
   * Razorpay order. The client never supplies amounts — it only says which
   * products and how many.
   */
  async createOrder(customerId, requestedItems, { addressId, phoneNumber } = {}) {
    if (!razorpay.isConfigured()) return NOT_CONFIGURED;

    if (!Array.isArray(requestedItems) || requestedItems.length === 0) {
      return { error: 'No order items supplied', status: 400 };
    }

    const customer = await Customer.findByPk(customerId);
    if (!customer) return { error: 'Customer not found', status: 404 };

    // A delivery order must resolve to a saved Address row. Checkout used to
    // send a free-text string that reached only Razorpay's notes, leaving
    // every order with a null shipping_address_id and nothing to deliver
    // against. (Phase 3 pickup orders will legitimately have no address.)
    if (addressId == null) {
      return { error: 'A delivery address is required', status: 400 };
    }
    const address = await Address.findByPk(Number.parseInt(addressId, 10) || 0);
    if (!address) return { error: 'Address not found', status: 400 };
    if (String(address.customerId) !== String(customerId)) {
      return { error: 'Address does not belong to this customer', status: 403 };
    }

    const products = await Product.findAll({
      where: { id: requestedItems.map((item) => item.productId) },
    });
    const productsById = new Map(products.map((p) => [String(p.id), p]));

    const lineItems = [];
    for (const item of requestedItems) {
      const product = productsById.get(String(item.productId));
      if (!product) {
        return { error: `Product ${item.productId} not found`, status: 400 };
      }
      if (!product.available) {
        return { error: `${product.name} is no longer available`, status: 400 };
      }

      const quantity = Number(item.quantity);
      if (!Number.isInteger(quantity) || quantity < 1) {
        return { error: `Invalid quantity for ${product.name}`, status: 400 };
      }
      if (product.stockQuantity < quantity) {
        return {
          error: `Only ${product.stockQuantity} left of ${product.name}`,
          status: 400,
        };
      }

      lineItems.push({ product, quantity, unitPricePaise: unitPricePaise(product) });
    }

    const totalAmountPaise = lineItems.reduce(
      (sum, line) => sum + line.unitPricePaise * line.quantity,
      0
    );
    if (totalAmountPaise < MIN_AMOUNT_PAISE) {
      return { error: 'Order total must be at least ₹1', status: 400 };
    }

    const orderNumber = generateOrderNumber();
    const order = await sequelize.transaction(async (transaction) => {
      const created = await OrderRecord.create(
        {
          customerId,
          orderNumber,
          status: 'PLACED',
          paymentStatus: 'PENDING',
          totalAmountPaise,
          shippingAddressId: address.id,
        },
        { transaction }
      );

      await OrderItem.bulkCreate(
        lineItems.map((line) => ({
          orderId: created.id,
          productId: line.product.id,
          shopId: line.product.shopId,
          quantity: line.quantity,
          unitPricePaise: line.unitPricePaise,
        })),
        { transaction }
      );

      return created;
    });

    let razorpayOrder;
    try {
      razorpayOrder = await razorpay.getClient().orders.create({
        amount: totalAmountPaise,
        currency: CURRENCY,
        receipt: orderNumber,
        // Denormalised into the Razorpay dashboard for support lookups; the
        // Address row remains the source of truth.
        notes: {
          ...sanitizeNotes({ shippingAddress: formatAddress(address), phoneNumber }),
          orderNumber,
        },
      });
    } catch (err) {
      await order.update({ status: 'CANCELLED', paymentStatus: 'FAILED' });
      const reason = err?.error?.description || err.message;
      return { error: `Razorpay order creation failed: ${reason}`, status: 502 };
    }

    await order.update({ razorpayOrderId: razorpayOrder.id });

    return {
      orderId: order.id,
      orderNumber,
      razorpayOrderId: razorpayOrder.id,
      amountPaise: totalAmountPaise,
      currency: CURRENCY,
      keyId: razorpay.getKeyId(),
    };
  },

  /**
   * Confirms a payment by recomputing Razorpay's HMAC signature with the key
   * secret. Only a signature produced by Razorpay can pass, so a client cannot
   * mark its own order paid.
   */
  async verifyPayment(customerId, { razorpayOrderId, razorpayPaymentId, razorpaySignature }) {
    if (!razorpay.isConfigured()) return NOT_CONFIGURED;

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return {
        error: 'razorpayOrderId, razorpayPaymentId and razorpaySignature are all required',
        status: 400,
      };
    }

    const order = await OrderRecord.findOne({ where: { razorpayOrderId } });
    if (!order) return { error: 'Unknown Razorpay order', status: 404 };
    if (String(order.customerId) !== String(customerId)) {
      return { error: 'Order does not belong to this customer', status: 403 };
    }
    if (order.paymentStatus === 'PAID') {
      return {
        verified: true,
        orderId: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
      };
    }

    const expected = crypto
      .createHmac('sha256', razorpay.getKeySecret())
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');

    if (!signaturesMatch(expected, razorpaySignature)) {
      await order.update({ paymentStatus: 'FAILED' });
      return { error: 'Payment signature verification failed', status: 400 };
    }

    await order.update({
      paymentStatus: 'PAID',
      status: 'CONFIRMED',
      razorpayPaymentId,
      razorpaySignature,
    });

    return {
      verified: true,
      orderId: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
    };
  },
};

module.exports = paymentService;
