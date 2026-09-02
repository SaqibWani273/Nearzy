const jwtService = require('../services/jwtService');
const { NearzyUser } = require('../models');

/**
 * JWT authentication.
 *
 * Never rejects on its own — plenty of routes here are public and are happy to
 * serve an unauthenticated caller — but it records *why* authentication failed
 * in `req.authError` so `authorize` can answer 401 with a code the client can
 * act on. Without that, an expired token and a missing one looked identical
 * and the app had no way to know a refresh would fix it.
 */
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    req.authError = 'TOKEN_INVALID';
    return next();
  }

  try {
    const { claims, expired } = jwtService.inspectToken(token);
    if (!claims) {
      req.authError = expired ? 'TOKEN_EXPIRED' : 'TOKEN_INVALID';
      return next();
    }

    const email = claims.sub;
    if (!email) {
      req.authError = 'TOKEN_INVALID';
      return next();
    }

    const user = await NearzyUser.findOne({ where: { email } });
    if (!user) {
      // The token verifies but the account behind it is gone. Refreshing
      // cannot help, so this is a sign-out, not a retry.
      req.authError = 'ACCOUNT_NOT_FOUND';
      return next();
    }

    // Attach user info to request
    req.user = {
      id: user.id,
      email: user.email,
      role: claims.role || `ROLE_${user.role}`, // e.g. ROLE_CUSTOMER, ROLE_SHOP_OWNER, ROLE_ADMIN
      rawRole: user.role,
    };
  } catch (err) {
    req.authError = 'TOKEN_INVALID';
  }

  next();
};

module.exports = authenticate;
