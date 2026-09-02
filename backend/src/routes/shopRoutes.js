const express = require('express');
const router = express.Router();
const shopService = require('../services/shopService');
const authorize = require('../middleware/authorize');

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
    const result = await shopService.loginShop(email, password);
    if (result.error) {
      return res.status(result.status || 400).json(result.error);
    }
    res.json(result.token);
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
    const token = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
    const result = await shopService.getShop(token);
    if (result && result.error) {
      return res.status(result.status || 400).json(result.error);
    }
    res.json(result);
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

module.exports = router;
