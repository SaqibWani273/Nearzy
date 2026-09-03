'use strict';

const { QueryTypes } = require('sequelize');
const { sequelize } = require('../models');
const alertService = require('../services/alertService');

/**
 * Predictive replenishment.
 *
 * A plain "stock below N" rule is wrong for a marketplace where one shop sells
 * three shawls a month and another sells forty loaves a day: the same
 * threshold is either constant noise or a warning that arrives after the
 * stockout. So the signal here is *days of cover* — how long the stock on hand
 * lasts at the rate the item is actually moving — and an item is only flagged
 * when it is both running low and selling faster than its own recent normal.
 */

// Sold-out is reported by the STOCKOUT branch, not as an infinite-urgency
// low-stock warning.
const CRITICAL_DAYS_OF_COVER = 1;
const WARNING_DAYS_OF_COVER = 3;

// Below this, a "spike" is one customer buying two of something. Not news.
const MIN_RECENT_UNITS = 2;

// How much faster than its 7-day mean an item must be moving to count as
// accelerating. 1.0 would fire on ordinary noise.
const ACCELERATION_FACTOR = 1.3;

/**
 * Units sold per product over two windows, for products that sold anything at
 * all in the last week.
 *
 * Cancelled orders are excluded: goods that were never handed over did not
 * consume stock (the cancellation path returns it), so counting them would
 * inflate velocity and cry wolf. Unpaid orders are excluded for the same
 * reason — a PENDING payment may never complete.
 */
const VELOCITY_SQL = `
  SELECT
    p.id                AS "productId",
    p.shop_id           AS "shopId",
    p.name              AS "name",
    p.stock_quantity    AS "stockQuantity",
    p.available         AS "available",
    COALESCE(SUM(oi.quantity) FILTER (
      WHERE o.placed_at >= NOW() - INTERVAL '24 hours'
    ), 0)               AS "recentUnits",
    COALESCE(SUM(oi.quantity), 0) AS "weekUnits"
  FROM products p
  JOIN order_items  oi ON oi.product_id = p.id
  JOIN order_records o  ON o.id = oi.order_id
  -- order_records names its creation column placed_at, not created_at.
  WHERE o.placed_at >= NOW() - INTERVAL '7 days'
    AND o.status       <> 'CANCELLED'
    AND o.payment_status = 'PAID'
  GROUP BY p.id, p.shop_id, p.name, p.stock_quantity, p.available
`;

/**
 * Scans sales velocity and raises (or clears) a low-stock alert per product.
 *
 * Returns a summary rather than logging only, so it can be asserted on in a
 * test and reported by the manual runner.
 */
async function runReplenishmentScan() {
  const rows = await sequelize.query(VELOCITY_SQL, { type: QueryTypes.SELECT });

  const summary = { scanned: rows.length, raised: 0, refreshed: 0, resolved: 0 };

  for (const row of rows) {
    const stock = Number(row.stockQuantity);
    const recentUnits = Number(row.recentUnits);
    const weekUnits = Number(row.weekUnits);
    const dailyMean = weekUnits / 7;

    // The rate we expect tomorrow: yesterday if the item is accelerating,
    // otherwise its steadier weekly average.
    const velocity = Math.max(recentUnits, dailyMean);

    if (stock <= 0) {
      // Sold out supersedes "running low" — leaving both open would show two
      // cards for one product, the milder of which is now simply untrue.
      summary.resolved += await alertService.resolveFor({
        shopId: row.shopId,
        productId: row.productId,
        types: ['LOW_STOCK'],
      });

      // The availability hook has already pulled it from the feed; the alert
      // exists to tell the owner why their item vanished.
      const { created } = await alertService.raise({
        shopId: row.shopId,
        productId: row.productId,
        type: 'STOCKOUT',
        severity: 'CRITICAL',
        title: `${row.name} is sold out`,
        body: `It sold ${weekUnits} in the last 7 days and is now hidden from customers. Restock to bring it back.`,
      });
      created ? summary.raised++ : summary.refreshed++;
      continue;
    }

    const daysOfCover = velocity > 0 ? stock / velocity : Infinity;
    const accelerating = dailyMean > 0
      ? recentUnits >= dailyMean * ACCELERATION_FACTOR
      : recentUnits >= MIN_RECENT_UNITS;

    const lowEnough = daysOfCover <= WARNING_DAYS_OF_COVER;
    const shouldWarn = lowEnough && recentUnits >= MIN_RECENT_UNITS && accelerating;

    if (!shouldWarn) {
      // Restocked, or the rush passed. Close anything still open for it.
      summary.resolved += await alertService.resolveFor({
        shopId: row.shopId,
        productId: row.productId,
        types: ['LOW_STOCK', 'STOCKOUT'],
      });
      continue;
    }

    const days = Math.max(0, Math.round(daysOfCover * 10) / 10);
    const { created } = await alertService.raise({
      shopId: row.shopId,
      productId: row.productId,
      type: 'LOW_STOCK',
      severity: daysOfCover <= CRITICAL_DAYS_OF_COVER ? 'CRITICAL' : 'WARNING',
      title: `${row.name} runs out in about ${days} ${days === 1 ? 'day' : 'days'}`,
      body:
        `${stock} left, selling ${recentUnits} in the last 24h ` +
        `against a 7-day average of ${dailyMean.toFixed(1)}/day. Restock soon.`,
    });
    created ? summary.raised++ : summary.refreshed++;
  }

  return summary;
}

module.exports = { runReplenishmentScan };
