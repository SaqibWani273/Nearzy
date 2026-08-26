const express = require('express');
const router = express.Router();
const customerService = require('../services/customerService');
const authorize = require('../middleware/authorize');

/**
 * @swagger
 * tags:
 *   - name: Customer Auth
 *     description: Customer registration, email verification, and login
 *   - name: Customer
 *     description: Customer profile, cart management, and product browsing
 */

/**
 * @swagger
 * /customer/register:
 *   post:
 *     tags: [Customer Auth]
 *     summary: Register a new customer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email: { type: string }
 *               password: { type: string }
 *               username: { type: string }
 *     responses:
 *       200: { description: Successfully registered }
 */
router.post('/register', async (req, res, next) => {
  try {
    const result = await customerService.registerCustomer(req.body);
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
 * /customer/verify-email:
 *   get:
 *     tags: [Customer Auth]
 *     summary: Verify customer email
 *     parameters:
 *       - in: query
 *         name: token
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Email verified successfully }
 */
router.get('/verify-email', handleVerifyEmail);
router.post('/verify-email', handleVerifyEmail);

async function handleVerifyEmail(req, res, next) {
  try {
    const token = req.query.token;
    const result = await customerService.verifyEmail(token);
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
 * /customer/login:
 *   post:
 *     tags: [Customer Auth]
 *     summary: Login customer
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
    const result = await customerService.loginCustomer(email, password);
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
 * /customer/get-all-products:
 *   get:
 *     tags: [Customer Auth]
 *     summary: Get all products
 *     responses:
 *       200: { description: Products retrieved }
 */
router.get('/get-all-products', async (req, res, next) => {
  try {
    const products = await customerService.getAllProducts();
    res.json(products);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /customer/me:
 *   post:
 *     tags: [Customer]
 *     summary: Get current customer profile
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { type: string }
 *     responses:
 *       200: { description: Customer profile retrieved }
 */
router.post('/me', authorize('CUSTOMER'), async (req, res, next) => {
  try {
    const token = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
    const customer = await customerService.getCustomer(token);
    if (!customer) {
      return res.status(400).json('invalid token');
    }
    res.json(customer);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /customer/update:
 *   post:
 *     tags: [Customer]
 *     summary: Update customer profile
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Customer updated }
 */
router.post('/update', authorize('CUSTOMER'), async (req, res, next) => {
  try {
    const result = await customerService.updateCustomer(req.body);
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
 * /customer/update-cart-items:
 *   post:
 *     tags: [Customer]
 *     summary: Update cart items
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               customerId: { type: integer }
 *               cartItems: { type: array }
 *     responses:
 *       200: { description: Cart updated }
 */
router.post('/update-cart-items', authorize('CUSTOMER'), async (req, res, next) => {
  try {
    const { customerId, cartItems } = req.body;
    const result = await customerService.updateCartItems(customerId, cartItems);
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
 * /customer/get-products-by-ids:
 *   post:
 *     tags: [Customer]
 *     summary: Get products by IDs
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               productIds: { type: array, items: { type: integer } }
 *     responses:
 *       200: { description: Products retrieved }
 */
router.post('/get-products-by-ids', authorize('CUSTOMER'), async (req, res, next) => {
  try {
    const { productIds } = req.body;
    const products = await customerService.fetchProductsByIds(productIds);
    res.json(products);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
