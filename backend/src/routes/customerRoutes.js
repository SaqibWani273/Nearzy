const express = require('express');
const router = express.Router();
const customerService = require('../services/customerService');
const paymentService = require('../services/paymentService');
const authorize = require('../middleware/authorize');

/**
 * @swagger
 * tags:
 *   - name: Customer Auth
 *     description: Customer registration, email verification, and login
 *   - name: Customer
 *     description: Customer profile, cart management, and product browsing
 *   - name: Customer Payments
 *     description: Razorpay order creation and payment verification
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
    const products = await customerService.getAllProducts({
      page: req.query.page,
      pageSize: req.query.pageSize,
    });
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

/**
 * @swagger
 * /customer/shops-near-location:
 *   get:
 *     tags: [Customer]
 *     summary: Browse shops near a given location
 *     description: >
 *       Returns paginated active shops filtered by city/state/pincode (text match)
 *       and/or a geographic radius (Haversine) around a lat-lng coordinate.
 *       At least one location param must be supplied.
 *     parameters:
 *       - in: query
 *         name: city
 *         schema: { type: string }
 *         description: City name (case-insensitive partial match)
 *       - in: query
 *         name: state
 *         schema: { type: string }
 *         description: State name (case-insensitive partial match)
 *       - in: query
 *         name: pincode
 *         schema: { type: string }
 *         description: Pincode (case-insensitive partial match)
 *       - in: query
 *         name: latitude
 *         schema: { type: number }
 *         description: Customer latitude for radius search
 *       - in: query
 *         name: longitude
 *         schema: { type: number }
 *         description: Customer longitude for radius search
 *       - in: query
 *         name: radiusKm
 *         schema: { type: number, default: 10 }
 *         description: Search radius in kilometres (default 10)
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Paginated shops list
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 total: { type: integer }
 *                 page: { type: integer }
 *                 limit: { type: integer }
 *                 totalPages: { type: integer }
 *                 shops: { type: array }
 *       400: { description: No location params provided }
 */
router.get('/shops-near-location', async (req, res, next) => {
  try {
    const { city, state, pincode, latitude, longitude, radiusKm, page, limit } = req.query;

    if (!city && !state && !pincode && (latitude == null || longitude == null)) {
      return res.status(400).json({
        error: 'At least one location parameter is required: city, state, pincode, or latitude+longitude',
      });
    }

    const result = await customerService.getShopsNearLocation({
      city, state, pincode, latitude, longitude, radiusKm, page, limit,
    });
    res.json(result);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /customer/location-specialities:
 *   get:
 *     tags: [Customer]
 *     summary: Get location-specific specialities and discovery feed
 *     description: >
 *       Returns a curated discovery feed for the given location.
 *       Sections include category spotlights (e.g. "Kashmiri Kehwa & Tea",
 *       "Handcrafted Shawls") derived from product categories present in
 *       local shops, plus an "Affordable Finds" section.
 *     parameters:
 *       - in: query
 *         name: city
 *         schema: { type: string }
 *       - in: query
 *         name: state
 *         schema: { type: string }
 *       - in: query
 *         name: pincode
 *         schema: { type: string }
 *       - in: query
 *         name: latitude
 *         schema: { type: number }
 *       - in: query
 *         name: longitude
 *         schema: { type: number }
 *       - in: query
 *         name: radiusKm
 *         schema: { type: number, default: 10 }
 *     responses:
 *       200:
 *         description: Discovery feed with sections
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 location: { type: object }
 *                 locationLabel: { type: string }
 *                 sections:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       sectionTitle: { type: string }
 *                       sectionSubtitle: { type: string }
 *                       type:
 *                         type: string
 *                         enum: [AFFORDABLE, CATEGORY_SPOTLIGHT]
 *                       products: { type: array }
 *       400: { description: No location params provided }
 */
router.get('/location-specialities', async (req, res, next) => {
  try {
    const { city, state, pincode, latitude, longitude, radiusKm } = req.query;

    if (!city && !state && !pincode && (latitude == null || longitude == null)) {
      return res.status(400).json({
        error: 'At least one location parameter is required: city, state, pincode, or latitude+longitude',
      });
    }

    const result = await customerService.getLocationSpecialities({
      city, state, pincode, latitude, longitude, radiusKm,
    });
    res.json(result);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /customer/affordable-products:
 *   get:
 *     tags: [Customer]
 *     summary: Get affordable products in a location
 *     description: >
 *       Returns paginated products from shops in the given location, sorted
 *       cheapest-first. Optionally cap results by `maxPriceInPaise`.
 *     parameters:
 *       - in: query
 *         name: city
 *         schema: { type: string }
 *       - in: query
 *         name: state
 *         schema: { type: string }
 *       - in: query
 *         name: pincode
 *         schema: { type: string }
 *       - in: query
 *         name: latitude
 *         schema: { type: number }
 *       - in: query
 *         name: longitude
 *         schema: { type: number }
 *       - in: query
 *         name: radiusKm
 *         schema: { type: number, default: 10 }
 *       - in: query
 *         name: maxPriceInPaise
 *         schema: { type: integer }
 *         description: Upper price cap in paise (e.g. 50000 = ₹500)
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Paginated products sorted cheapest-first
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 total: { type: integer }
 *                 page: { type: integer }
 *                 limit: { type: integer }
 *                 totalPages: { type: integer }
 *                 products: { type: array }
 *       400: { description: No location params provided }
 */
router.get('/affordable-products', async (req, res, next) => {
  try {
    const { city, state, pincode, latitude, longitude, radiusKm, maxPriceInPaise, page, limit } = req.query;

    if (!city && !state && !pincode && (latitude == null || longitude == null)) {
      return res.status(400).json({
        error: 'At least one location parameter is required: city, state, pincode, or latitude+longitude',
      });
    }

    const result = await customerService.getAffordableProductsByLocation({
      city, state, pincode, latitude, longitude, radiusKm, maxPriceInPaise, page, limit,
    });
    res.json(result);
  } catch (err) {
    next(err);
  }
});

/**
 * Resolves the Customer row for the caller's JWT. Payment routes never take a
 * customerId from the request body — that would let one customer order under
 * another's account.
 */
async function requireCustomerId(req, res) {
  const customerId = await customerService.getCustomerIdByUserId(req.user.id);
  if (!customerId) {
    res.status(404).json({ message: 'No customer profile for this account' });
    return null;
  }
  return customerId;
}

/**
 * @swagger
 * /customer/payment/config:
 *   get:
 *     tags: [Customer Payments]
 *     summary: Public Razorpay checkout config (key id only — never the secret)
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Checkout config }
 *       503: { description: Payment gateway not configured }
 */
router.get('/payment/config', authorize('CUSTOMER'), async (req, res, next) => {
  try {
    const result = paymentService.getConfig();
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
 * /customer/payment/create-order:
 *   post:
 *     tags: [Customer Payments]
 *     summary: Create a pending order and its matching Razorpay order
 *     description: >
 *       The order total is computed server-side from current product prices.
 *       The client supplies only product ids and quantities.
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               orderItems:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     productId: { type: integer }
 *                     quantity: { type: integer }
 *               shippingAddress: { type: string }
 *               billingAddress: { type: string }
 *               phoneNumber: { type: string }
 *     responses:
 *       200: { description: Razorpay order created }
 *       400: { description: Invalid order }
 *       502: { description: Razorpay rejected the order }
 *       503: { description: Payment gateway not configured }
 */
router.post('/payment/create-order', authorize('CUSTOMER'), async (req, res, next) => {
  try {
    const customerId = await requireCustomerId(req, res);
    if (!customerId) return;

    const { orderItems, shippingAddress, billingAddress, phoneNumber } = req.body;
    const result = await paymentService.createOrder(customerId, orderItems, {
      shippingAddress,
      billingAddress,
      phoneNumber,
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
 * /customer/payment/verify:
 *   post:
 *     tags: [Customer Payments]
 *     summary: Verify a Razorpay payment signature and mark the order paid
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               razorpayOrderId: { type: string }
 *               razorpayPaymentId: { type: string }
 *               razorpaySignature: { type: string }
 *     responses:
 *       200: { description: Payment verified }
 *       400: { description: Signature verification failed }
 *       403: { description: Order belongs to another customer }
 *       404: { description: Unknown Razorpay order }
 */
router.post('/payment/verify', authorize('CUSTOMER'), async (req, res, next) => {
  try {
    const customerId = await requireCustomerId(req, res);
    if (!customerId) return;

    const result = await paymentService.verifyPayment(customerId, req.body);
    if (result.error) {
      return res.status(result.status || 400).json({ message: result.error });
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
