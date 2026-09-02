'use strict';

/**
 * Maps order entities to the JSON shapes the Flutter client expects.
 *
 * Written alongside a fresh Dart `Order` model, so unlike productDto these
 * field names are chosen rather than inherited: amounts keep their `Paise`
 * suffix so there is no ambiguity about units, and nothing is nested behind
 * an `orderDetails` wrapper the way the previous Java-era payload was.
 *
 * The same rule as productDto still applies — raw ORM rows must never reach
 * the wire, because they carry internal column names and the password hash.
 */

const str = (v) => (v == null ? '' : String(v));
const numOr = (v, fallback = 0) => (v == null ? fallback : Number(v));
const numOrNull = (v) => (v == null ? null : Number(v));
const iso = (v) => (v == null ? null : new Date(v).toISOString());

/** Address -> client Address. */
function toAddressDto(address) {
  if (!address) return null;
  return {
    id: address.id ?? null,
    label: str(address.label),
    line1: str(address.line1),
    line2: str(address.line2),
    city: str(address.city),
    state: str(address.state),
    postalCode: str(address.postalCode),
    country: str(address.country),
    latitude: numOrNull(address.latitude),
    longitude: numOrNull(address.longitude),
    isDefault: Boolean(address.isDefault),
  };
}

/**
 * Single-line rendering of an address, for the Razorpay dashboard note and
 * for shop-facing order lists that only need one string.
 */
function formatAddress(address) {
  if (!address) return '';
  return [
    address.line1,
    address.line2,
    address.city,
    address.state,
    address.postalCode,
    address.country,
  ]
    .map((part) => (part == null ? '' : String(part).trim()))
    .filter(Boolean)
    .join(', ');
}

/**
 * OrderItem (+ product -> images, shop) -> one order line.
 *
 * `unitPricePaise` and `discountPaise` are snapshots taken when the order was
 * placed, so the line total is computed from those and never from the
 * product's current price — a shop repricing an item must not retroactively
 * change what a customer was charged.
 */
function toOrderItemDto(item) {
  const product = item?.product;
  const images = [...(product?.images ?? [])]
    .sort((a, b) => (a?.displayOrder ?? 0) - (b?.displayOrder ?? 0))
    .map((image) => str(image?.url));

  const quantity = numOr(item?.quantity, 1);
  const unitPricePaise = numOr(item?.unitPricePaise);
  const discountPaise = numOr(item?.discountPaise);

  return {
    id: item?.id ?? null,
    productId: item?.productId ?? null,
    // The product row may have been deleted since the order was placed, so
    // the client must tolerate an empty name rather than a null cast.
    name: str(product?.name),
    brand: str(product?.brand),
    sku: str(product?.sku),
    images,
    quantity,
    unitPricePaise,
    discountPaise,
    // Gross, so the lines sum to the order's subtotal. The order-level
    // discount is deducted once, below — a per-line discount is not always
    // a share of it, so netting it here made the receipt fail to add up.
    lineTotalPaise: unitPricePaise * quantity,
    shopId: item?.shopId ?? null,
    shopName: str(item?.shop?.name ?? product?.shop?.name),
  };
}

/**
 * OrderRecord -> client Order.
 *
 * `forShop` narrows the payload to one shop's perspective: only that shop's
 * line items, plus the customer's contact details so the order can actually
 * be fulfilled. Totals are recomputed from the visible lines in that mode,
 * because the order's own total covers items belonging to other shops.
 */
function toOrderDto(order, { forShop = false, shopId = null } = {}) {
  const allItems = order?.items ?? [];
  const visibleItems = forShop && shopId != null
    ? allItems.filter((item) => String(item.shopId) === String(shopId))
    : allItems;

  const items = visibleItems.map(toOrderItemDto);
  const subtotalPaise = items.reduce((sum, item) => sum + item.lineTotalPaise, 0);

  // A shop must not see the whole order's discount against its own slice, so
  // there the only attributable figure is the sum of its own line discounts.
  const discountAmountPaise = forShop
    ? items.reduce((sum, item) => sum + item.discountPaise, 0)
    : numOr(order?.discountAmountPaise);

  const dto = {
    id: order?.id ?? null,
    orderNumber: str(order?.orderNumber),
    status: str(order?.status),
    paymentStatus: str(order?.paymentStatus),
    placedAt: iso(order?.placedAt),
    updatedAt: iso(order?.updatedAt),
    items,
    itemCount: items.reduce((sum, item) => sum + item.quantity, 0),
    subtotalPaise,
    discountAmountPaise,
    // subtotal - discount == total, so the client can render a receipt that
    // adds up. For a customer that identity already holds against the stored
    // total; for a shop the figures are recomputed from its own lines.
    totalAmountPaise: forShop
      ? subtotalPaise - discountAmountPaise
      : numOr(order?.totalAmountPaise),
    shippingAddress: toAddressDto(order?.shippingAddress),
  };

  if (forShop) {
    const customer = order?.customer;
    const fullName = [customer?.firstName, customer?.lastName]
      .filter(Boolean)
      .join(' ')
      .trim();
    dto.customer = {
      id: customer?.id ?? null,
      // Falls back to the login handle only when the profile name is unset,
      // which is common for accounts that registered and never filled it in.
      name: fullName || str(customer?.user?.username),
      phoneNumber: str(customer?.phoneNumber),
    };
    dto.shippingAddressText = formatAddress(order?.shippingAddress);
  }

  return dto;
}

module.exports = {
  toOrderDto,
  toOrderItemDto,
  toAddressDto,
  formatAddress,
};
