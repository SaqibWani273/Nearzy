const express = require('express');
const router = express.Router();
const commonService = require('../services/commonService');
const jwtService = require('../services/jwtService');
const refreshTokenService = require('../services/refreshTokenService');
const { NearzyUser, Customer, Shop } = require('../models');
const authorize = require('../middleware/authorize');
const { toCustomerDto, toShopDto } = require('../dto/productDto');
const { callerIdentity } = require('../utils/identity');

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
    // Identity comes from the verified Authorization header. It used to be
    // parsed out of a token posted in the body, which meant a client that had
    // just refreshed its access token got a 500 on `claims.role` unless it
    // remembered to update the body too.
    const { email, role } = callerIdentity(req);
    if (!email) {
      return res.status(401).json({ message: 'Authentication required' });
    }

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
      responseBody.model = toCustomerDto(customer);
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
      if (!shop) {
        return res.status(400).json('No shop profile for this account');
      }
      // The client parses this with ShopModel1, whose generated casts are
      // non-nullable and keyed to the DTO shape. A raw Sequelize row carries
      // `user.passwordHash` (never `password`), category objects instead of
      // names, `longitude` instead of the client's misspelled `longtitude`,
      // and leaves the verification fields nested — so the very first cast
      // threw and every shop sign-in failed. It also leaked the hash.
      responseBody.model = toShopDto(shop);
    }

    res.json(responseBody);
  } catch (err) {
    next(err);
  }
});

/**
 * @swagger
 * /user/refresh:
 *   post:
 *     tags: [Common]
 *     summary: Exchange a refresh token for a new access token
 *     description: >
 *       Refresh tokens are single-use. Each call rotates the token, so the
 *       response's refreshToken must replace the one that was sent. Replaying
 *       a spent token revokes the entire chain and answers 401
 *       REFRESH_TOKEN_REUSED.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               refreshToken: { type: string }
 *     responses:
 *       200: { description: New access and refresh token issued }
 *       401: { description: Refresh token invalid, expired, or already used }
 */
router.post('/refresh', async (req, res, next) => {
  try {
    // Accepts a JSON body, a bare string body, or the header — the app posts
    // JSON, but express.text() is mounted and curl users reach for both.
    const presented =
      (req.body && typeof req.body === 'object' ? req.body.refreshToken : null) ||
      (typeof req.body === 'string' ? req.body.trim() : null) ||
      req.headers['x-refresh-token'];

    const result = await refreshTokenService.rotate(presented, {
      deviceLabel: req.headers['user-agent'],
    });

    if (result.error) {
      return res.status(result.status || 401).json({
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
 * /user/logout:
 *   post:
 *     tags: [Common]
 *     summary: Revoke a refresh token
 *     description: >
 *       Ends the session the refresh token belongs to. Pass allDevices to end
 *       every session for the signed-in account instead.
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               refreshToken: { type: string }
 *               allDevices: { type: boolean }
 *     responses:
 *       200: { description: Session revoked }
 */
router.post('/logout', async (req, res, next) => {
  try {
    const body = req.body && typeof req.body === 'object' ? req.body : {};
    const presented =
      body.refreshToken ||
      (typeof req.body === 'string' ? req.body.trim() : null) ||
      req.headers['x-refresh-token'];

    // Signing out everywhere needs a *valid* access token to say whose
    // sessions to end; a single-device sign-out only needs the token itself,
    // which is what lets an app with an expired access token still sign out.
    if (body.allDevices === true) {
      if (!req.user) {
        return res.status(401).json({ message: 'Authentication required' });
      }
      const revoked = await refreshTokenService.revokeAllForUser(req.user.id);
      return res.json({ message: 'Signed out on all devices', revoked });
    }

    const revoked = await refreshTokenService.revoke(presented);
    res.json({ message: 'Signed out', revoked });
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
