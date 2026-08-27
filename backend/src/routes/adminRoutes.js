const express = require('express');
const router = express.Router();
const adminService = require('../services/adminService');
const authorize = require('../middleware/authorize');

/**
 * @swagger
 * tags:
 *   - name: Admin Auth
 *     description: Public endpoints for admin authentication and registration
 *   - name: Admin
 *     description: Authenticated endpoints for admin operations
 */

/**
 * @swagger
 * /admin/register:
 *   post:
 *     tags: [Admin Auth]
 *     summary: Register a new admin
 *     description: Registers a new admin user using an admin password record and a secret code.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               user:
 *                 type: object
 *                 properties:
 *                   email: { type: string }
 *                   password: { type: string }
 *                   username: { type: string }
 *               secretCode: { type: string }
 *     responses:
 *       200: { description: Admin registered successfully }
 */
router.post('/register', async (req, res, next) => {
  try {
    const userData = req.body.user || req.body.myUser;
    const { secretCode } = req.body;
    const result = await adminService.registerAdmin(userData, secretCode);
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
 * /admin/verify-email:
 *   get:
 *     tags: [Admin Auth]
 *     summary: Verify admin email
 *     parameters:
 *       - in: query
 *         name: token
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Email verified successfully }
 *   post:
 *     tags: [Admin Auth]
 *     summary: Verify admin email
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
    const result = await adminService.verifyEmail(token);
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
 * /admin/login:
 *   post:
 *     tags: [Admin Auth]
 *     summary: Admin login
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
    const result = await adminService.login(email, password);
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
 * /admin/add-category:
 *   post:
 *     tags: [Admin]
 *     summary: Add product category
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name: { type: string }
 *               slug: { type: string }
 *               imageUrl: { type: string }
 *               description: { type: string }
 *               isTopCategory: { type: boolean }
 *               displayOrder: { type: integer }
 *     responses:
 *       200: { description: Category added successfully }
 */
router.post('/add-category', authorize('ADMIN'), async (req, res, next) => {
  try {
    const result = await adminService.addCategory(req.body);
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
 * /admin/me:
 *   post:
 *     tags: [Admin]
 *     summary: Verify admin token
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { type: string }
 *     responses:
 *       200: { description: Token verified successfully }
 */
router.post('/me', authorize('ADMIN'), async (req, res, next) => {
  try {
    const token = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
    const result = await adminService.verifyToken(token);
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
 * /admin/test-get:
 *   get:
 *     tags: [Admin Auth]
 *     summary: Test GET endpoint
 *     responses:
 *       200: { description: Test successful }
 */
router.get('/test-get', (req, res) => {
  res.json('test get successful');
});

/**
 * @swagger
 * /admin/test-post:
 *   post:
 *     tags: [Admin Auth]
 *     summary: Test POST endpoint
 *     responses:
 *       200: { description: Test successful }
 */
router.post('/test-post', (req, res) => {
  res.json('test post successful');
});

module.exports = router;
