const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const NearzyUser = sequelize.define('NearzyUser', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    username: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: true,
    },
    passwordHash: {
      type: DataTypes.STRING,
      allowNull: false,
      field: 'password_hash',
    },
    email: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false,
    },
    role: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'CUSTOMER',
      validate: {
        isIn: [['CUSTOMER', 'SHOP_OWNER', 'ADMIN', 'SHOP']],
      },
    },
    isEmailVerified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      field: 'is_email_verified',
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
    tableName: 'nearzy_users',
    timestamps: true,
    underscored: true,
  });

  return NearzyUser;
};
