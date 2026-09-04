const express = require('express');
const router = express.Router();
const shopService = require('../services/shopService');
const listingDraftService = require('../services/listingDraftService');
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
 *     summary: Add a product to the signed-in shop's inventory
 *     description: >
 *       The shop is taken from the token; a `shopId` in the body is ignored.
 *       Price is in paise, like every other money field in the API.
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, categoryId, priceInPaise]
 *             properties:
 *               name: { type: string }
 *               categoryId: { type: integer }
 *               priceInPaise: { type: integer, description: Whole paise, must be > 0 }
 *               stockQuantity: { type: integer, default: 0 }
 *               discountPercent: { type: number, default: 0 }
 *               brand: { type: string }
 *               sku: { type: string }
 *               shortDescription: { type: string }
 *               completeDescription: { type: string }
 *               images: { type: array, items: { type: string } }
 *               colors: { type: array, items: { type: string } }
 *     responses:
 *       200: { description: Product added }
 *       400: { description: Missing or invalid field (the message names it) }
 *       404: { description: No shop profile for this account }
 */
router.post('/add-product', authorize('SHOP'), async (req, res, next) => {
  try {
    const result = await shopService.addProduct(req.user.id, req.body);
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
 * /shop/products/draft:
 *   post:
 *     tags: [Shop]
 *     summary: Read a product photo and return a draft listing to confirm
 *     description: >
 *       Answers the "listing takes too long" objection: the owner photographs
 *       the packet and confirms what comes back instead of typing seven fields.
 *       Creates nothing — the draft goes to the app, the owner corrects it and
 *       adds the price, and POST /shop/add-product does the writing.
 *       Never returns a price: a wrong name is a nuisance, a wrong price costs
 *       the shop money.
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               imageUrl: { type: string, description: Cloudinary URL of the uploaded photo }
 *               imageBase64: { type: string, description: Fallback for a photo not yet uploaded }
 *               mimeType: { type: string, default: image/jpeg }
 *     responses:
 *       200: { description: Draft fields, per-field confidence, and what needs attention }
 *       400: { description: No image supplied }
 *       502: { description: The photo could not be read — fill the form in by hand }
 *       504: { description: The model took too long — fill the form in by hand }
 *       503: { description: Listing assistant not configured (GEMINI_API_KEY unset) }
 */
router.post('/products/draft', authorize('SHOP'), async (req, res, next) => {
  try {
    const result = await listingDraftService.draftFromImage({
      imageUrl: req.body?.imageUrl,
      imageBase64: req.body?.imageBase64,
      mimeType: req.body?.mimeType,
    });
    if (result.error) {
      return res.status(result.status || 400).json({
        message: result.error,
        code: result.code,
      });
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

/**
 * @swagger
 * /shop/products/{id}:
 *   patch:
 *     tags: [Shop]
 *     summary: Update price, stock, availability or markdown settings
 *     description: >
 *       Only whitelisted fields are accepted. The product must belong to the
 *       shop behind the bearer token; anything else answers 404.
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
 *               priceInPaise: { type: integer }
 *               discountPercent: { type: number }
 *               stockQuantity: { type: integer }
 *               available: { type: boolean }
 *               markdownEnabled: { type: boolean }
 *               markdownFloorPercent: { type: number }
 *     responses:
 *       200: { description: Updated product }
 *       400: { description: Invalid field value }
 *       404: { description: Product not found in this shop }
 */
/**
 * @swagger
 * /shop/products/{id}:
 *   get:
 *     tags: [Shop]
 *     summary: One product from this shop's inventory
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200: { description: Product }
 *       404: { description: Product not found in this shop }
 */
router.get('/products/:id', authorize('SHOP'), async (req, res, next) => {
  try {
    const result = await shopService.getMyProduct(req.user.id, req.params.id);
    if (result.error) {
      return res.status(result.status || 400).json({ message: result.error });
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});

router.patch('/products/:id', authorize('SHOP'), async (req, res, next) => {
  try {
    const result = await shopService.updateProduct(req.user.id, req.params.id, req.body);
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
 * /shop/products/bulk-stock:
 *   post:
 *     tags: [Shop]
 *     summary: Apply a batch of stock adjustments by SKU
 *     description: >
 *       Backs the barcode scanner. Each entry carries a `sku` plus either a
 *       relative `delta` or an absolute `stockQuantity`. Unknown SKUs are
 *       reported per row rather than failing the whole batch.
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               entries:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     sku: { type: string }
 *                     delta: { type: integer }
 *                     stockQuantity: { type: integer }
 *     responses:
 *       200: { description: Per-SKU results }
 *       400: { description: Empty or oversized batch }
 */
router.post('/products/bulk-stock', authorize('SHOP'), async (req, res, next) => {
  try {
    const entries = Array.isArray(req.body) ? req.body : req.body?.entries;
    const result = await shopService.bulkAdjustStock(req.user.id, entries);
    if (result.error) {
      return res.status(result.status || 400).json({ message: result.error });
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Dashboard & alerts
// ---------------------------------------------------------------------------

/**
 * @swagger
 * /shop/dashboard:
 *   get:
 *     tags: [Shop]
 *     summary: Triage payload for the shop home screen
 *     description: >
 *       Counts and open alerts the owner can act on — orders awaiting
 *       dispatch, low or sold-out stock, verification state.
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Dashboard payload }
 *       404: { description: No shop profile for this account }
 */
router.get('/dashboard', authorize('SHOP'), async (req, res, next) => {
  try {
    const result = await shopService.getDashboard(req.user.id);
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
 * /shop/alerts:
 *   get:
 *     tags: [Shop]
 *     summary: This shop's alerts, most urgent first
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: status
 *         schema: { type: string, default: OPEN }
 *         description: OPEN (default), ALL, or one of UNREAD/READ/RESOLVED
 *     responses:
 *       200: { description: Alert list }
 */
router.get('/alerts', authorize('SHOP'), async (req, res, next) => {
  try {
    const result = await shopService.listAlerts(req.user.id, { status: req.query.status });
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
 * /shop/alerts/{id}:
 *   patch:
 *     tags: [Shop]
 *     summary: Mark an alert read or resolved
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
 *               status: { type: string, enum: [UNREAD, READ, RESOLVED] }
 *     responses:
 *       200: { description: Updated alert }
 *       404: { description: Alert not found in this shop }
 */
router.patch('/alerts/:id', authorize('SHOP'), async (req, res, next) => {
  try {
    const result = await shopService.setAlertStatus(req.user.id, req.params.id, req.body?.status);
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
