'use strict';

/**
 * Normalises page/limit query params into Sequelize's limit/offset pair.
 *
 * Lifted out of customerService so the order endpoints share one definition
 * of "page 2" with the product endpoints. `zeroBased` exists because the
 * Flutter PagingController on the product feed starts at page 0, while the
 * discovery endpoints were built 1-based.
 */
function paging({ page = 1, limit = 20, zeroBased = false, maxLimit = 100 } = {}) {
  const parsedLimit = Number.parseInt(limit, 10);
  const parsedPage = Number.parseInt(page, 10);
  const safeLimit = Math.min(Math.max(Number.isNaN(parsedLimit) ? 20 : parsedLimit, 1), maxLimit);
  const fallbackPage = zeroBased ? 0 : 1;
  const rawPage = Math.max(Number.isNaN(parsedPage) ? fallbackPage : parsedPage, fallbackPage);
  const pageIndex = zeroBased ? rawPage : rawPage - 1;
  return { limit: safeLimit, offset: pageIndex * safeLimit, page: rawPage };
}

/** The `{total, page, limit, totalPages, <key>}` envelope every list endpoint returns. */
function envelope(key, { count, rows, limit, page }) {
  return {
    total: count,
    page,
    limit,
    totalPages: Math.ceil(count / limit),
    [key]: rows,
  };
}

module.exports = { paging, envelope };
