const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const EmailConfirmation = sequelize.define('EmailConfirmation', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    token: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false,
    },
    userId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'user_id',
    },
    createdAt: {
      type: DataTypes.DATE,
      field: 'created_at',
    },
    expiresAt: {
      type: DataTypes.DATE,
      allowNull: false,
      field: 'expires_at',
    },
    used: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  }, {
    tableName: 'email_confirmations',
    timestamps: true,
    updatedAt: false,
    underscored: true,
  });

  return EmailConfirmation;
};
