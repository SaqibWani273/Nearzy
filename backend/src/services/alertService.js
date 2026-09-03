'use strict';

const { Op } = require('sequelize');
const { ShopAlert, Product } = require('../models');

/**
 * Writing and reading the shop's triage list.
 *
 * The one rule that shapes this file: **alerts are upserted, never appended**.
 * The jobs behind them run on a schedule, so an alert that is merely inserted
 * each time would turn one real problem ("you are about to run out of Kani
 * shawls") into twenty-four identical rows a day, and the dashboard would be
 * useless by lunchtime.
 */

const alertService = {
  /**
   * Raises an alert, or refreshes the open one that already says this.
   *
   * Identity is (shop, product, type) among rows that are not yet RESOLVED. A
   * resolved alert is deliberately *not* matched: the owner dealt with it, and
   * the problem recurring later is genuinely new news.
   */
  async raise({ shopId, productId = null, type, severity = 'INFO', title, body = null }) {
    const existing = await ShopAlert.findOne({
      where: {
        shop_id: shopId,
        product_id: productId,
        type,
        status: { [Op.ne]: 'RESOLVED' },
      },
    });

    if (existing) {
      // Refresh the wording and severity — the numbers in the title move as
      // stock drains — but leave `status` alone so re-running a job does not
      // mark an alert the owner has already read as unread again.
      existing.severity = severity;
      existing.title = title;
      existing.body = body;
      existing.changed('updatedAt', true);
      await existing.save();
      return { alert: existing, created: false };
    }

    const alert = await ShopAlert.create({
      shopId, productId, type, severity, title, body, status: 'UNREAD',
    });
    return { alert, created: true };
  },

  /**
   * Closes any open alert of `type` for a product whose problem has gone away
   * — restocked, or taken off markdown. Without this, a fixed problem would
   * sit on the dashboard until someone dismissed it by hand.
   */
  async resolveFor({ shopId, productId, types }) {
    const [count] = await ShopAlert.update(
      { status: 'RESOLVED', resolvedAt: new Date() },
      {
        where: {
          shop_id: shopId,
          product_id: productId,
          type: { [Op.in]: types },
          status: { [Op.ne]: 'RESOLVED' },
        },
      }
    );
    return count;
  },

  /** GET /shop/alerts — the open list, most urgent first. */
  async listForShop(shopId, { status = 'OPEN' } = {}) {
    const where = { shop_id: shopId };
    if (status === 'OPEN') {
      where.status = { [Op.ne]: 'RESOLVED' };
    } else if (status !== 'ALL') {
      where.status = String(status).toUpperCase();
    }

    const rows = await ShopAlert.findAll({
      where,
      include: [{ association: 'product', attributes: ['id', 'name', 'sku', 'stockQuantity'] }],
      // CRITICAL before WARNING before INFO, then newest. Postgres sorts the
      // stored strings, so the ordering is spelled out rather than relying on
      // the words happening to sort correctly (they do not).
      order: [
        [
          ShopAlert.sequelize.literal(
            "CASE severity WHEN 'CRITICAL' THEN 0 WHEN 'WARNING' THEN 1 ELSE 2 END"
          ),
          'ASC',
        ],
        ['created_at', 'DESC'],
      ],
      limit: 100,
    });

    return rows.map(toAlertDto);
  },

  /** PATCH /shop/alerts/:id — mark read or resolved. */
  async setStatus(shopId, alertId, status) {
    const next = String(status || '').trim().toUpperCase();
    if (!['UNREAD', 'READ', 'RESOLVED'].includes(next)) {
      return { error: `Unknown status '${status}'`, status: 400 };
    }

    const id = Number.parseInt(alertId, 10);
    if (Number.isNaN(id)) return { error: 'Invalid alert id', status: 400 };

    const alert = await ShopAlert.findByPk(id);
    // Scoped to the caller's shop, so an id from another shop reads as absent.
    if (!alert || String(alert.shopId) !== String(shopId)) {
      return { error: 'Alert not found', status: 404 };
    }

    alert.status = next;
    alert.resolvedAt = next === 'RESOLVED' ? new Date() : null;
    await alert.save();

    return { message: `Alert ${next.toLowerCase()}`, alert: toAlertDto(alert) };
  },

  /** Counts the dashboard header needs. */
  async countsForShop(shopId) {
    const rows = await ShopAlert.findAll({
      where: { shop_id: shopId, status: { [Op.ne]: 'RESOLVED' } },
      attributes: ['severity', [ShopAlert.sequelize.fn('COUNT', '*'), 'n']],
      group: ['severity'],
      raw: true,
    });

    const bySeverity = Object.fromEntries(rows.map((r) => [r.severity, Number(r.n)]));
    return {
      total: Object.values(bySeverity).reduce((a, b) => a + b, 0),
      critical: bySeverity.CRITICAL ?? 0,
      warning: bySeverity.WARNING ?? 0,
      info: bySeverity.INFO ?? 0,
    };
  },
};

/** ShopAlert -> the client's alert card. */
function toAlertDto(alert) {
  return {
    id: alert.id ?? null,
    type: alert.type,
    severity: alert.severity,
    title: alert.title ?? '',
    body: alert.body ?? '',
    status: alert.status,
    createdAt: alert.createdAt ?? null,
    productId: alert.productId ?? null,
    product: alert.product
      ? {
          id: alert.product.id,
          name: alert.product.name ?? '',
          sku: alert.product.sku ?? '',
          stockQuantity: alert.product.stockQuantity ?? 0,
        }
      : null,
  };
}

module.exports = alertService;
module.exports.toAlertDto = toAlertDto;
