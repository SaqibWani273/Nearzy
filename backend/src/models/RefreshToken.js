const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const RefreshToken = sequelize.define('RefreshToken', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    // Only the SHA-256 of the token is stored. A refresh token is a bearer
    // credential with a month-long life, so a leaked database dump must not
    // hand out working sessions the way a plaintext column would.
    tokenHash: {
      type: DataTypes.STRING(64),
      unique: true,
      allowNull: false,
      field: 'token_hash',
    },
    userId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'user_id',
    },
    // Every rotation of the same sign-in shares a family id, so presenting an
    // already-rotated token can revoke the whole chain rather than just itself.
    familyId: {
      type: DataTypes.STRING(36),
      allowNull: false,
      field: 'family_id',
    },
    expiresAt: {
      type: DataTypes.DATE,
      allowNull: false,
      field: 'expires_at',
    },
    revokedAt: {
      type: DataTypes.DATE,
      allowNull: true,
      field: 'revoked_at',
    },
    // Why the row stopped being usable: 'rotated', 'logout', 'logout_all',
    // 'reuse_detected'. Purely diagnostic, but it is what makes a support
    // question about "signed out unexpectedly" answerable.
    revokedReason: {
      type: DataTypes.STRING(32),
      allowNull: true,
      field: 'revoked_reason',
    },
    // Free-text device hint shown in the app's session list, e.g. the User-Agent.
    deviceLabel: {
      type: DataTypes.STRING(120),
      allowNull: true,
      field: 'device_label',
    },
    createdAt: {
      type: DataTypes.DATE,
      field: 'created_at',
    },
    updatedAt: {
      type: DataTypes.DATE,
      field: 'updated_at',
    },
  }, {
    tableName: 'refresh_tokens',
    timestamps: true,
    underscored: true,
    indexes: [
      { fields: ['user_id'] },
      { fields: ['family_id'] },
    ],
  });

  return RefreshToken;
};
