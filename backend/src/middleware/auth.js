const jwtService = require('../services/jwtService');
const { NearzyUser } = require('../models');

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

    const user = await NearzyUser.findOne({ where: { email } });
    if (!user) {
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
    // Token invalid — proceed unauthenticated
  }

  next();
};

module.exports = authenticate;
