/**
 * Creates middleware that requires the user to have one of the specified roles.
 * Usage: authorize('CUSTOMER'), authorize('ADMIN'), authorize('SHOP_OWNER'), authorize('SHOP')
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
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
      return res.status(403).json({ message: 'Access denied. Insufficient permissions.' });
    }

    next();
  };
};

module.exports = authorize;
