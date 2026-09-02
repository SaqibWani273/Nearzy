'use strict';

const jwtService = require('../services/jwtService');

/**
 * Who the request is for.
 *
 * The `/me` endpoints were written to read the caller's identity out of a JWT
 * posted in the *body*, which the middleware never validated — and which the
 * app now has to keep in sync with a rotating access token. `req.user` is
 * already resolved from the verified Authorization header, so prefer it and
 * keep the body token only as a fallback for older clients.
 *
 * @param {import('express').Request} req
 * @returns {{ email: string|null, role: string|null }}
 */
function callerIdentity(req) {
  if (req.user && req.user.email) {
    return { email: req.user.email, role: req.user.role || null };
  }

  const token = typeof req.body === 'string' ? req.body.trim() : null;
  if (!token) return { email: null, role: null };

  const claims = jwtService.extractClaims(token);
  if (!claims) return { email: null, role: null };
  return { email: claims.sub || null, role: claims.role || null };
}

module.exports = { callerIdentity };
