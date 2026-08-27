const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Address = sequelize.define('Address', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    customerId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'customer_id',
    },
    label: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    line1: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    line2: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    city: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    state: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    postalCode: {
      type: DataTypes.STRING,
      allowNull: false,
      field: 'postal_code',
    },
    country: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    latitude: {
      type: DataTypes.DOUBLE,
      allowNull: true,
    },
    longitude: {
      type: DataTypes.DOUBLE,
      allowNull: true,
    },
    isDefault: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      field: 'is_default',
    },
  }, {
    tableName: 'addresses',
    timestamps: false,
    underscored: true,
  });

  return Address;
};
