/**
 * Creates middleware that requires the user to have one of the specified roles.
 * Usage: authorize('CUSTOMER'), authorize('ADMIN'), authorizeAny('CUSTOMER', 'SHOP')
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
    }

    // req.user.role is like "ROLE_CUSTOMER"
    // roles param expects "CUSTOMER", "SHOP", "ADMIN"
    const userRole = req.user.role || '';
    const hasRole = roles.some((role) => userRole === `ROLE_${role}`);

    if (!hasRole) {
      return res.status(403).json({ message: 'Access denied. Insufficient permissions.' });
    }

    next();
  };
};

module.exports = authorize;
