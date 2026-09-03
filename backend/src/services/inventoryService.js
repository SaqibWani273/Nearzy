'use strict';

const { Product, OrderItem } = require('../models');

/**
 * Stock movement.
 *
 * Stock used to be write-only in the opposite sense to orders: the checkout
 * path *read* `stockQuantity` to reject an oversell, but nothing ever wrote it
 * back, so every completed sale left the count untouched and inventory drifted
 * from reality immediately. This is the one place that moves it.
 */

/**
 * Moves every line of an order's stock by `direction` — `-1` to consume it on
 * payment, `+1` to return it on cancellation.
 *
 * Rows are locked FOR UPDATE and written through an instance `.save()` rather
 * than `Product.decrement()`, for two reasons:
 *
 *   * the lock serialises two customers checking out the last unit, and
 *   * only an instance save runs Product's `beforeSave` hook, which is what
 *     flips `available` to false at zero. A bulk `update()`/`decrement()` skips
 *     instance hooks silently and would leave sold-out items on the feed.
 *
 * The caller supplies the transaction, because moving stock is never the whole
 * story — it commits with the order status change that caused it.
 */
async function applyStockDelta(orderId, direction, transaction) {
  const items = await OrderItem.findAll({
    where: { order_id: orderId },
    transaction,
  });

  for (const item of items) {
    const product = await Product.findByPk(item.productId, {
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!product) continue;

    // Clamped at zero. A negative count would read as "in stock" again the
    // moment anything was added to it, and no oversell is worth that.
    product.stockQuantity = Math.max(
      0,
      product.stockQuantity + direction * item.quantity
    );
    await product.save({ transaction });
  }
}

module.exports = { applyStockDelta };
