const jwt = require('jsonwebtoken');

/**
 * JWT Service — handles token generation, verification, and claims extraction.
 * Uses lazy access to env vars so dotenv has time to load.
 */
const jwtService = {
  /**
   * @returns {string} The JWT secret key from environment.
   */
  _getSecretKey() {
    return process.env.JWT_SECRET_KEY || 'ec43d3c23a733e8cc060af85b859222cfa9ff68b4109e443a625a458eae5ad00';
  },

  /**
   * @returns {number} Token expiration in hours.
   */
  _getExpirationHours() {
    return parseInt(process.env.JWT_EXPIRATION_HOURS || '48', 10);
  },

  /**
   * Access-token lifetime in seconds.
   *
   * JWT_EXPIRATION_MINUTES wins when set, so the refresh path can be exercised
   * end to end (set it to 1 and every call after a minute takes the refresh
   * branch) without dropping the hour-granularity setting deployments use.
   * @returns {number}
   */
  getAccessTokenTtlSeconds() {
    const minutes = parseInt(process.env.JWT_EXPIRATION_MINUTES || '0', 10);
    if (Number.isFinite(minutes) && minutes > 0) {
      return minutes * 60;
    }
    return this._getExpirationHours() * 60 * 60;
  },

  /**
   * Generate a JWT token for the given user.
   * @param {{ email: string, role?: string, roles?: string }} user
   * @returns {string} Signed JWT token.
   */
  generateToken(user) {
    const roleValue = user.role || user.roles || 'CUSTOMER';
    const payload = {
      name: user.email,
      role: roleValue.startsWith('ROLE_') ? roleValue : `ROLE_${roleValue}`,
      sub: user.email,
    };
    return jwt.sign(payload, this._getSecretKey(), {
      expiresIn: this.getAccessTokenTtlSeconds(),
    });
  },

  /**
   * Verify a token, distinguishing "expired" from "malformed".
   *
   * The client refreshes on expiry but must sign out on a forged token, and
   * `verifyToken` collapses both into null — so the middleware uses this.
   * @param {string} token
   * @returns {{ claims: object|null, expired: boolean }}
   */
  inspectToken(token) {
    try {
      return { claims: jwt.verify(token, this._getSecretKey()), expired: false };
    } catch (err) {
      return { claims: null, expired: err.name === 'TokenExpiredError' };
    }
  },

  /**
   * Verify a token and return decoded payload, or null if invalid.
   * @param {string} token
   * @returns {object|null}
   */
  verifyToken(token) {
    try {
      return jwt.verify(token, this._getSecretKey());
    } catch (err) {
      return null;
    }
  },

  /**
   * Extract all claims from a token.
   * @param {string} token
   * @returns {object|null}
   */
  extractClaims(token) {
    try {
      return jwt.verify(token, this._getSecretKey());
    } catch (err) {
      return null;
    }
  },

  /**
   * Extract the email (subject) from a token.
   * @param {string} token
   * @returns {string|null}
   */
  extractEmail(token) {
    const claims = this.extractClaims(token);
    return claims ? claims.sub : null;
  },

  /**
   * Check whether a token is valid and not expired.
   * @param {string} token
   * @returns {boolean}
   */
  isTokenValid(token) {
    try {
      jwt.verify(token, this._getSecretKey());
      return true;
    } catch (err) {
      return false;
    }
  },
};

module.exports = jwtService;
