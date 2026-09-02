/**
 * Creates middleware that requires the user to have one of the specified roles.
 * Usage: authorize('CUSTOMER'), authorize('ADMIN'), authorize('SHOP_OWNER'), authorize('SHOP')
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      // `code` is what tells the client whether to refresh and retry
      // (TOKEN_EXPIRED) or drop the session and ask for a password
      // (everything else).
      return res.status(401).json({
        message:
          req.authError === 'TOKEN_EXPIRED'
            ? 'Access token expired'
            : 'Authentication required',
        code: req.authError || 'TOKEN_MISSING',
      });
    }

    // Support both ROLE_SHOP and ROLE_SHOP_OWNER interchangeably
    const normalizedRoles = roles.map((r) => {
      if (r === 'SHOP') return 'ROLE_SHOP_OWNER';
      return r.startsWith('ROLE_') ? r : `ROLE_${r}`;
    });

    const userRole = req.user.role || '';
    const hasRole = normalizedRoles.some((role) => {
      if (userRole === role) return true;
      if (userRole === 'ROLE_SHOP' && role === 'ROLE_SHOP_OWNER') return true;
      if (userRole === 'ROLE_SHOP_OWNER' && role === 'ROLE_SHOP') return true;
      return false;
    });

    if (!hasRole) {
      return res.status(403).json({
        message: 'Access denied. Insufficient permissions.',
        code: 'ROLE_MISMATCH',
      });
    }

    next();
  };
};

module.exports = authorize;
