'use strict';

const { Op } = require('sequelize');
const { Product } = require('../models');
const alertService = require('../services/alertService');

/**
 * End-of-day price markdown.
 *
 * Perishables and slow movers are worth more discounted than unsold, so the
 * discount escalates as the trading day closes and resets overnight.
 *
 * The engine only ever touches products whose owner set `markdownEnabled`.
 * That opt-in is the whole safety model: this code rewrites a price a merchant
 * chose, and doing that to an unenrolled product — however good the reasoning
 * — is not ours to do. `markdownFloorPercent` is the owner's floor, and the
 * engine never goes past it.
 */

// The trading day the ramp is measured against. Discount is at its base at
// START and reaches the owner's floor at END.
const RAMP_START_HOUR = 15;
const RAMP_END_HOUR = 21;

/**
 * How far through the markdown ramp we are, 0 to 1.
 *
 * Injectable so the schedule can be tested without waiting for evening.
 */
function rampProgress(now = new Date()) {
  const hour = now.getHours() + now.getMinutes() / 60;
  if (hour <= RAMP_START_HOUR) return 0;
  if (hour >= RAMP_END_HOUR) return 1;
  return (hour - RAMP_START_HOUR) / (RAMP_END_HOUR - RAMP_START_HOUR);
}

/**
 * Escalates the discount on every enrolled product toward its floor.
 *
 * Discounts only ever move *up* within a day. A customer who saw 30% off at
 * 19:00 should not find 20% at 19:30 because velocity ticked up; the reset
 * job is the only thing that walks a price back, and it does so overnight.
 */
async function runMarkdownSweep(now = new Date()) {
  const progress = rampProgress(now);
  const summary = { considered: 0, adjusted: 0, progress: Number(progress.toFixed(3)) };

  if (progress <= 0) return summary;

  const products = await Product.findAll({
    where: {
      markdown_enabled: true,
      available: true,
      stock_quantity: { [Op.gt]: 0 },
    },
  });
  summary.considered = products.length;

  for (const product of products) {
    const base = Number(product.baseDiscountPercent) || 0;
    const floor = Number(product.markdownFloorPercent) || 0;

    // Nothing to give away: the owner's floor is at or below what they already
    // discount by default.
    if (floor <= base) continue;

    const target = Math.round((base + (floor - base) * progress) * 10) / 10;
    const current = Number(product.discountPercent) || 0;
    if (target <= current) continue;

    product.discountPercent = target;
    await product.save();
    summary.adjusted++;

    await alertService.raise({
      shopId: product.shopId,
      productId: product.id,
      type: 'MARKDOWN_APPLIED',
      severity: 'INFO',
      title: `${product.name} marked down to ${target}% off`,
      body: `Automatic end-of-day markdown. Resets to ${base}% overnight.`,
    });
  }

  return summary;
}

/**
 * Returns every enrolled product to the discount its owner set.
 *
 * Restores `baseDiscountPercent` rather than zeroing the field: a shop that
 * runs a standing 15% off would otherwise lose it the first night the markdown
 * engine touched the product.
 */
async function runMarkdownReset() {
  const products = await Product.findAll({ where: { markdown_enabled: true } });
  const summary = { considered: products.length, reset: 0 };

  for (const product of products) {
    const base = Number(product.baseDiscountPercent) || 0;
    if (Number(product.discountPercent) === base) continue;

    product.discountPercent = base;
    await product.save();
    summary.reset++;

    await alertService.resolveFor({
      shopId: product.shopId,
      productId: product.id,
      types: ['MARKDOWN_APPLIED'],
    });
  }

  return summary;
}

module.exports = { runMarkdownSweep, runMarkdownReset, rampProgress };
