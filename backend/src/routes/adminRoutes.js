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
    const result = await adminService.login(email, password, { deviceLabel: req.headers['user-agent'] });
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
 * /admin/stats:
 *   get:
 *     tags: [Admin]
 *     summary: Platform counters for the admin overview
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Counts }
 */
router.get('/stats', authorize('ADMIN'), async (req, res, next) => {
  try {
    res.json(await adminService.getStats());
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /admin/demand-heatmap:
 *   get:
 *     tags: [Admin]
 *     summary: Order density by delivery location, grid-binned
 *     description: >
 *       Plots where orders were delivered so the admin can see which areas
 *       justify widening the discovery radius. Orders only — search queries
 *       are not logged.
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: days
 *         schema: { type: integer, default: 30 }
 *       - in: query
 *         name: precision
 *         schema: { type: integer, default: 2 }
 *         description: Grid resolution in decimal places (2 ~ 1.1km cells)
 *     responses:
 *       200: { description: Weighted points }
 */
router.get('/demand-heatmap', authorize('ADMIN'), async (req, res, next) => {
  try {
    res.json(await adminService.getDemandHeatmap({
      days: req.query.days,
      precision: req.query.precision,
    }));
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Shop verification
//
// `adminService.verifyShop` has existed since the shop model landed but was
// never routed, so applications collected in `shop_verifications` with no way
// to read or decide them. These two endpoints are that missing surface.
// ---------------------------------------------------------------------------

/**
 * @swagger
 * /admin/shop-verifications:
 *   get:
 *     tags: [Admin]
 *     summary: The shop verification queue, oldest submission first
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: status
 *         schema: { type: string, default: PENDING }
 *         description: PENDING, APPROVED, REJECTED, or ALL
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200: { description: Paginated verifications }
 *       400: { description: Unknown status }
 */
router.get('/shop-verifications', authorize('ADMIN'), async (req, res, next) => {
  try {
    const result = await adminService.listShopVerifications({
      page: req.query.page,
      limit: req.query.limit,
      status: req.query.status,
    });
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
 * /admin/shop-verifications/{shopId}/decide:
 *   post:
 *     tags: [Admin]
 *     summary: Approve or reject a pending shop application
 *     description: >
 *       Records the deciding admin and the decision time. Only a PENDING
 *       application can be decided; a repeat decision answers 409.
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: shopId
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
 *                 enum: [APPROVED, REJECTED]
 *     responses:
 *       200: { description: Decision recorded }
 *       400: { description: Unknown status }
 *       404: { description: No verification record for that shop }
 *       409: { description: Already decided }
 */
router.post('/shop-verifications/:shopId/decide', authorize('ADMIN'), async (req, res, next) => {
  try {
    const result = await adminService.verifyShop(
      req.params.shopId,
      req.user.id,
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
