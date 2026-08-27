const express = require('express');
const router = express.Router();
const commonService = require('../services/commonService');
const jwtService = require('../services/jwtService');
const { NearzyUser, Customer, Shop } = require('../models');
const authorize = require('../middleware/authorize');

/**
 * @swagger
 * tags:
 *   - name: Common
 *     description: Common utility endpoints shared across different user roles
 */

/**
 * @swagger
 * /user/test:
 *   get:
 *     tags: [Common]
 *     summary: Test endpoint
 *     responses:
 *       200: { description: Tested successfully }
 */
router.get('/test', (req, res) => {
  res.json('tested successfully');
});

/**
 * @swagger
 * /user/me:
 *   post:
 *     tags: [Common]
 *     summary: Get current user profile
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: User profile retrieved }
 */
router.post('/me', authorize('CUSTOMER', 'SHOP', 'SHOP_OWNER'), async (req, res, next) => {
  try {
    const token = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
    const email = jwtService.extractEmail(token);
    const claims = jwtService.extractClaims(token);
    const role = claims.role;

    const user = await NearzyUser.findOne({ where: { email } });
    if (!user) {
      return res.status(400).json('User not found');
    }

    const responseBody = { role };

    if (role === 'ROLE_CUSTOMER') {
      const customer = await Customer.findOne({
        where: { user_id: user.id },
        include: [
          { association: 'user' },
          { association: 'addresses' },
          {
            association: 'cart',
            include: [{ association: 'items', include: [{ association: 'product' }] }],
          },
        ],
      });
      responseBody.model = customer;
    } else {
      const shop = await Shop.findOne({
        where: { user_id: user.id },
        include: [
          { association: 'user' },
          { association: 'locationInfo' },
          { association: 'verification' },
          { association: 'categories' },
        ],
      });
      responseBody.model = shop;
    }

    res.json(responseBody);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /user/get-all-categories:
 *   get:
 *     tags: [Common]
 *     summary: Get all product categories
 *     responses:
 *       200: { description: Categories retrieved }
 */
router.get('/get-all-categories', async (req, res, next) => {
  try {
    const categories = await commonService.getAllCategories();
    res.json(categories);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /user/email-exists:
 *   post:
 *     tags: [Common]
 *     summary: Check if email exists
 *     responses:
 *       200: { description: Check completed }
 */
router.post('/email-exists', async (req, res, next) => {
  try {
    const email = typeof req.body === 'string' ? req.body : req.body.email || req.body;
    const exists = await commonService.emailExists(email);
    res.json(exists);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /user/username-exists:
 *   post:
 *     tags: [Common]
 *     summary: Check if username exists
 *     responses:
 *       200: { description: Check completed }
 */
router.post('/username-exists', async (req, res, next) => {
  try {
    const username = typeof req.body === 'string' ? req.body : req.body.username || req.body;
    const exists = await commonService.usernameExists(username);
    res.json(exists);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
