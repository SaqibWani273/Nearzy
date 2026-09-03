'use strict';

const { Op } = require('sequelize');
const { sequelize, OrderRecord, OrderItem, Shop } = require('../models');
const { toOrderDto } = require('../dto/orderDto');
const { paging, envelope } = require('../utils/paging');
const { applyStockDelta } = require('./inventoryService');

/**
 * Reading orders back.
 *
 * Orders were write-only until now: paymentService created them and marked
 * them paid, but nothing ever fetched one, so the client shipped a stub that
 * returned an empty list. Everything here is read-mostly; the only mutation
 * is a shop advancing an order's status.
 */

/** Forward-only lifecycle. CANCELLED is reachable from anything unterminated. */
const FORWARD_FLOW = ['PLACED', 'CONFIRMED', 'SHIPPED', 'DELIVERED'];
const TERMINAL = ['DELIVERED', 'CANCELLED'];

/**
 * The include tree an order needs to render.
 *
 * Note that items are loaded *unfiltered* even for the shop view, and the DTO
 * narrows them instead. Putting a `where` on a hasMany include alongside
 * `limit` makes Sequelize apply the filter outside its pagination subquery,
 * which silently returns the wrong page.
 */
function orderIncludes({ forShop = false } = {}) {
  const includes = [
    {
      association: 'items',
      include: [
        { association: 'product', include: [{ association: 'images' }] },
        { association: 'shop', attributes: ['id', 'name', 'slug', 'phoneNumber'] },
      ],
    },
    { association: 'shippingAddress' },
  ];

  if (forShop) {
    includes.push({
      association: 'customer',
      // The hash must not even be loaded, let alone serialised.
      include: [{ association: 'user', attributes: { exclude: ['passwordHash'] } }],
    });
  }

  return includes;
}

/** Accepts a single status or a comma-separated list; ignores unknown values. */
function statusFilter(status) {
  if (!status) return null;
  const wanted = String(status)
    .split(',')
    .map((s) => s.trim().toUpperCase())
    .filter((s) => FORWARD_FLOW.includes(s) || s === 'CANCELLED');
  return wanted.length ? { [Op.in]: wanted } : null;
}

const orderService = {
  /**
   * GET /customer/orders
   * The signed-in customer's order history, newest first.
   */
  async listCustomerOrders(customerId, { page, limit, status } = {}) {
    const page_ = paging({ page, limit });
    const where = { customer_id: customerId };

    const wantedStatus = statusFilter(status);
    if (wantedStatus) where.status = wantedStatus;

    const { count, rows } = await OrderRecord.findAndCountAll({
      where,
      include: orderIncludes(),
      order: [['placed_at', 'DESC'], ['id', 'DESC']],
      limit: page_.limit,
      offset: page_.offset,
      // Counting over a hasMany include counts join rows, not orders.
      distinct: true,
    });

    return envelope('orders', {
      count,
      rows: rows.map((order) => toOrderDto(order)),
      limit: page_.limit,
      page: page_.page,
    });
  },

  /**
   * GET /customer/orders/:id
   * 403 rather than 404 on someone else's order is deliberate: the id space
   * is sequential, so a 404 would still confirm which ids exist. The
   * ownership check mirrors paymentService.verifyPayment.
   */
  async getCustomerOrder(customerId, orderId) {
    const id = Number.parseInt(orderId, 10);
    if (Number.isNaN(id)) return { error: 'Invalid order id', status: 400 };

    const order = await OrderRecord.findByPk(id, { include: orderIncludes() });
    if (!order) return { error: 'Order not found', status: 404 };
    if (String(order.customerId) !== String(customerId)) {
      return { error: 'Order does not belong to this customer', status: 403 };
    }

    return toOrderDto(order);
  },

  /** Resolves the caller's own shop from their JWT user id. */
  async _shopForUser(userId) {
    return Shop.findOne({ where: { user_id: userId }, attributes: ['id'] });
  },

  /**
   * GET /shop/orders
   * Orders containing at least one of this shop's items, newest first. Each
   * order is narrowed to that shop's own lines by the DTO.
   *
   * `userId` comes from the JWT, never the request, so one shop cannot read
   * another's order book.
   */
  async listShopOrders(userId, { page, limit, status } = {}) {
    const shop = await this._shopForUser(userId);
    if (!shop) return { error: 'No shop profile for this account', status: 404 };

    // Two steps on purpose. Resolving the id set first keeps the paginated
    // query free of a filtered hasMany include, which Sequelize mispages.
    const lines = await OrderItem.findAll({
      where: { shop_id: shop.id },
      attributes: ['orderId'],
      group: ['order_id'],
    });
    const orderIds = lines.map((line) => line.orderId);

    const page_ = paging({ page, limit });
    if (!orderIds.length) {
      return envelope('orders', { count: 0, rows: [], limit: page_.limit, page: page_.page });
    }

    const where = { id: { [Op.in]: orderIds } };

    const wantedStatus = statusFilter(status);
    if (wantedStatus) where.status = wantedStatus;

    const { count, rows } = await OrderRecord.findAndCountAll({
      where,
      include: orderIncludes({ forShop: true }),
      order: [['placed_at', 'DESC'], ['id', 'DESC']],
      limit: page_.limit,
      offset: page_.offset,
      distinct: true,
    });

    return envelope('orders', {
      count,
      rows: rows.map((order) => toOrderDto(order, { forShop: true, shopId: shop.id })),
      limit: page_.limit,
      page: page_.page,
    });
  },

  /**
   * PATCH /shop/orders/:id/status
   *
   * Only the immediate next step is allowed, or a cancellation. Letting a
   * shop jump straight to DELIVERED would let it skip the states a customer
   * relies on for tracking, and a status can never move backwards.
   */
  async updateOrderStatus(userId, orderId, nextStatus) {
    const shop = await this._shopForUser(userId);
    if (!shop) return { error: 'No shop profile for this account', status: 404 };

    const id = Number.parseInt(orderId, 10);
    if (Number.isNaN(id)) return { error: 'Invalid order id', status: 400 };

    const target = String(nextStatus || '').trim().toUpperCase();
    if (!FORWARD_FLOW.includes(target) && target !== 'CANCELLED') {
      return { error: `Unknown status '${nextStatus}'`, status: 400 };
    }

    const order = await OrderRecord.findByPk(id, { include: orderIncludes({ forShop: true }) });
    if (!order) return { error: 'Order not found', status: 404 };

    const ownsALine = (order.items ?? []).some(
      (item) => String(item.shopId) === String(shop.id)
    );
    if (!ownsALine) {
      return { error: 'Order contains none of this shop\'s items', status: 403 };
    }

    if (TERMINAL.includes(order.status)) {
      return { error: `Order is already ${order.status}`, status: 400 };
    }

    if (target !== 'CANCELLED') {
      const currentIndex = FORWARD_FLOW.indexOf(order.status);
      if (FORWARD_FLOW.indexOf(target) !== currentIndex + 1) {
        const expected = FORWARD_FLOW[currentIndex + 1];
        return {
          error: `Cannot move from ${order.status} to ${target}; next is ${expected}`,
          status: 400,
        };
      }
    }

    // Cancelling returns the units the payment consumed. Without this the
    // stock drawn down at checkout would be destroyed permanently: a cancelled
    // order's goods were never shipped, but the count would never recover.
    // Only a paid order reserved anything, so only a paid order gives it back.
    const restocks = target === 'CANCELLED' && order.paymentStatus === 'PAID';

    await sequelize.transaction(async (transaction) => {
      await order.update({ status: target }, { transaction });
      if (restocks) {
        await applyStockDelta(order.id, 1, transaction);
      }
    });

    await order.reload({ include: orderIncludes({ forShop: true }) });

    return toOrderDto(order, { forShop: true, shopId: shop.id });
  },
};

module.exports = orderService;
