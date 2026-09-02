const express = require('express');
const router = express.Router();
const shopService = require('../services/shopService');
const orderService = require('../services/orderService');
const authorize = require('../middleware/authorize');
const { toShopDto } = require('../dto/productDto');
const { callerIdentity } = require('../utils/identity');

/**
 * @swagger
 * tags:
 *   - name: Shop Auth
 *     description: Shop registration, email verification, and login
 *   - name: Shop
 *     description: Shop profile and product management
 */

/**
 * @swagger
 * /shop/register:
 *   post:
 *     tags: [Shop Auth]
 *     summary: Register a new shop
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200: { description: Shop registered successfully }
 */
router.post('/register', async (req, res, next) => {
  try {
    const result = await shopService.registerShop(req.body);
    if (result.error) {
      return res.status(result.status || 400).json(result.error);
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});

router.get('/verify-email', handleVerifyEmail);
router.post('/verify-email', handleVerifyEmail);

async function handleVerifyEmail(req, res, next) {
  try {
    const token = req.query.token;
    const result = await shopService.verifyEmail(token);
    if (result.error) {
      return res.status(result.status || 400).json(result.error);
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
}

/**
 * @swagger
 * /shop/login:
 *   post:
 *     tags: [Shop Auth]
 *     summary: Shop login
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email: { type: string }
 *               password: { type: string }
 *     responses:
 *       200: { description: Login successful }
 */
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const result = await shopService.loginShop(email, password, { deviceLabel: req.headers['user-agent'] });
    if (result.error) {
      return res.status(result.status || 400).json(result.error);
    }
    res.json(result.session);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /shop/me:
 *   post:
 *     tags: [Shop]
 *     summary: Get shop profile
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Shop profile retrieved }
 */
router.post('/me', authorize('SHOP'), async (req, res, next) => {
  try {
    const { email } = callerIdentity(req);
    const result = email ? await shopService.getShopByEmail(email) : null;
    if (result && result.error) {
      return res.status(result.status || 400).json(result.error);
    }
    if (!result) {
      return res.status(400).json('No shop profile for this account');
    }
    // Same DTO the discovery endpoints use: a raw row would leak the password
    // hash and doesn't match the client's ShopModel1 casts.
    res.json(toShopDto(result));
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /shop/add-product:
 *   post:
 *     tags: [Shop]
 *     summary: Add a new product
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Product added }
 */
router.post('/add-product', authorize('SHOP'), async (req, res, next) => {
  try {
    const result = await shopService.addProduct(req.body);
    if (result.error) {
      return res.status(result.status || 400).json(result.error);
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /shop/my-products:
 *   get:
 *     tags: [Shop]
 *     summary: The signed-in shop's own inventory (including unavailable items)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: q
 *         schema: { type: string }
 *         description: Filter by product name or SKU
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 50 }
 *     responses:
 *       200: { description: Paginated inventory }
 *       404: { description: No shop profile for this account }
 */
router.get('/my-products', authorize('SHOP'), async (req, res, next) => {
  try {
    const result = await shopService.getMyProducts(req.user.id, {
      page: req.query.page,
      limit: req.query.limit,
      q: req.query.q,
    });
    if (result.error) {
      return res.status(result.status || 400).json({ message: result.error });
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Orders
// ---------------------------------------------------------------------------

/**
 * @swagger
 * /shop/orders:
 *   get:
 *     tags: [Shop]
 *     summary: Orders containing this shop's items, newest first
 *     description: >
 *       Each order is narrowed to this shop's own line items, with the
 *       customer's contact details so it can be fulfilled. The shop is
 *       resolved from the bearer token, never from the request.
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *       - in: query
 *         name: status
 *         schema: { type: string }
 *     responses:
 *       200: { description: Paginated orders }
 *       404: { description: No shop profile for this account }
 */
router.get('/orders', authorize('SHOP'), async (req, res, next) => {
  try {
    const { page, limit, status } = req.query;
    const result = await orderService.listShopOrders(req.user.id, { page, limit, status });
    if (result.error) {
      return res.status(result.status || 400).json({ message: result.error });
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /shop/orders/{id}/status:
 *   patch:
 *     tags: [Shop]
 *     summary: Advance an order to the next status, or cancel it
 *     description: >
 *       Only the immediate next step in PLACED -> CONFIRMED -> SHIPPED ->
 *       DELIVERED is accepted, plus CANCELLED from any unterminated state.
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [CONFIRMED, SHIPPED, DELIVERED, CANCELLED]
 *     responses:
 *       200: { description: Updated order }
 *       400: { description: Illegal status transition }
 *       403: { description: Order contains none of this shop's items }
 *       404: { description: Order not found }
 */
router.patch('/orders/:id/status', authorize('SHOP'), async (req, res, next) => {
  try {
    const result = await orderService.updateOrderStatus(
      req.user.id,
      req.params.id,
      req.body?.status
    );
    if (result.error) {
      return res.status(result.status || 400).json({ message: result.error });
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
