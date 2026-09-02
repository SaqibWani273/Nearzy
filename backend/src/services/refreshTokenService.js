const crypto = require('crypto');
const { Op } = require('sequelize');
const { RefreshToken, NearzyUser } = require('../models');
const jwtService = require('./jwtService');

/** How long a refresh token stays usable, in days. */
const refreshTtlDays = () => parseInt(process.env.JWT_REFRESH_EXPIRATION_DAYS || '30', 10);

/** Refresh tokens are opaque random strings — nothing about them is a claim. */
const newOpaqueToken = () => crypto.randomBytes(48).toString('base64url');

/** Rows store the digest, never the token itself. */
const hash = (token) => crypto.createHash('sha256').update(token).digest('hex');

/**
 * Refresh-token lifecycle: issue on sign-in, rotate on every use, revoke on
 * sign-out. Rotation means a token is single-use, so a stolen one is only
 * good until the real client refreshes — at which point the theft surfaces
 * as a reuse and takes the whole family down.
 */
const refreshTokenService = {
  /**
   * Mint an access/refresh pair for a freshly authenticated user.
   * @param {object} user NearzyUser instance.
   * @param {{ deviceLabel?: string, familyId?: string }} [meta]
   */
  async issueSession(user, meta = {}) {
    const accessToken = jwtService.generateToken(user);
    const refreshToken = newOpaqueToken();
    const ttlSeconds = jwtService.getAccessTokenTtlSeconds();

    await RefreshToken.create({
      tokenHash: hash(refreshToken),
      userId: user.id,
      familyId: meta.familyId || crypto.randomUUID(),
      expiresAt: new Date(Date.now() + refreshTtlDays() * 24 * 60 * 60 * 1000),
      deviceLabel: (meta.deviceLabel || '').slice(0, 120) || null,
    });

    return {
      token: accessToken,
      // Spelled out as well as `token`, because "token" alone is ambiguous
      // once there are two of them.
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      expiresIn: ttlSeconds,
      expiresAt: new Date(Date.now() + ttlSeconds * 1000).toISOString(),
      refreshExpiresIn: refreshTtlDays() * 24 * 60 * 60,
      email: user.email,
      username: user.username,
      role: user.role.startsWith('ROLE_') ? user.role : `ROLE_${user.role}`,
    };
  },

  /**
   * Exchange a refresh token for a new pair, rotating the old one out.
   *
   * @param {string} presentedToken
   * @param {{ deviceLabel?: string }} [meta]
   * @returns {Promise<object>} A session, or `{ error, status, code }`.
   */
  async rotate(presentedToken, meta = {}) {
    if (typeof presentedToken !== 'string' || presentedToken.trim().length === 0) {
      return { error: 'Refresh token is required', status: 400, code: 'REFRESH_TOKEN_MISSING' };
    }

    const record = await RefreshToken.findOne({
      where: { tokenHash: hash(presentedToken.trim()) },
    });

    if (!record) {
      return { error: 'Invalid refresh token', status: 401, code: 'REFRESH_TOKEN_INVALID' };
    }

    if (record.revokedAt) {
      // A token that was rotated away is being replayed. The legitimate client
      // never does that under rotation, so treat it as a stolen copy and take
      // the whole chain down — including whatever the thief rotated into.
      if (record.revokedReason === 'rotated') {
        await this.revokeFamily(record.familyId, 'reuse_detected');
        return {
          error: 'Refresh token already used. Please sign in again.',
          status: 401,
          code: 'REFRESH_TOKEN_REUSED',
        };
      }
      // Deliberately revoked (sign-out, or a chain already burned down). No
      // theft to contain — just say the session is over.
      return {
        error: 'Session ended. Please sign in again.',
        status: 401,
        code: 'REFRESH_TOKEN_REVOKED',
      };
    }

    if (new Date(record.expiresAt) <= new Date()) {
      return { error: 'Refresh token expired', status: 401, code: 'REFRESH_TOKEN_EXPIRED' };
    }

    const user = await NearzyUser.findByPk(record.userId);
    if (!user) {
      await this.revokeFamily(record.familyId, 'logout_all');
      return { error: 'Account no longer exists', status: 401, code: 'REFRESH_TOKEN_INVALID' };
    }

    const session = await this.issueSession(user, {
      familyId: record.familyId,
      deviceLabel: meta.deviceLabel || record.deviceLabel,
    });

    record.revokedAt = new Date();
    record.revokedReason = 'rotated';
    await record.save();

    return session;
  },

  /** Revokes one token (sign-out on this device). Unknown tokens are a no-op. */
  async revoke(presentedToken, reason = 'logout') {
    if (typeof presentedToken !== 'string' || !presentedToken.trim()) return 0;
    const [count] = await RefreshToken.update(
      { revokedAt: new Date(), revokedReason: reason },
      { where: { tokenHash: hash(presentedToken.trim()), revokedAt: null } }
    );
    return count;
  },

  /** Revokes a whole rotation chain. */
  async revokeFamily(familyId, reason = 'logout') {
    const [count] = await RefreshToken.update(
      { revokedAt: new Date(), revokedReason: reason },
      { where: { familyId, revokedAt: null } }
    );
    return count;
  },

  /** Revokes every live session for a user (sign out everywhere). */
  async revokeAllForUser(userId, reason = 'logout_all') {
    const [count] = await RefreshToken.update(
      { revokedAt: new Date(), revokedReason: reason },
      { where: { userId, revokedAt: null } }
    );
    return count;
  },

  /**
   * Drops rows that can no longer authorise anything: expired, or revoked
   * long enough ago that reuse detection has nothing left to catch.
   */
  async purgeExpired() {
    const reuseWindow = new Date(Date.now() - refreshTtlDays() * 24 * 60 * 60 * 1000);
    return RefreshToken.destroy({
      where: {
        [Op.or]: [
          { expiresAt: { [Op.lt]: new Date() } },
          { revokedAt: { [Op.lt]: reuseWindow } },
        ],
      },
    });
  },
};

module.exports = refreshTokenService;
