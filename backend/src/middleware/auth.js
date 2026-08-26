const jwtService = require('../services/jwtService');
const { MyUser } = require('../models');

/**
 * JWT Authentication middleware.
 * Extracts Bearer token, verifies it, and attaches user info to req.user.
 * If no token or invalid token, request proceeds without authentication
 * (authorization is handled at route level).
 */
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    // Allow request to proceed — authorization checked at route level
    return next();
  }

  const token = authHeader.substring(7);

  try {
    const claims = jwtService.extractClaims(token);
    if (!claims) {
      return next();
    }

    const email = claims.sub;
    if (!email) {
      return next();
    }

    const user = await MyUser.findOne({ where: { email } });
    if (!user) {
      return next();
    }

    // Attach user info to request
    req.user = {
      id: user.id,
      email: user.email,
      roles: user.roles,
      role: claims.role, // e.g. ROLE_CUSTOMER
    };
  } catch (err) {
    // Token invalid — proceed unauthenticated
  }

  next();
};

module.exports = authenticate;
