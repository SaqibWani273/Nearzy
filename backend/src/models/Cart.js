const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Cart = sequelize.define('Cart', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    customerId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      unique: true,
      field: 'customer_id',
    },
    updatedAt: {
      type: DataTypes.DATE,
      field: 'updated_at',
    },
  }, {
    tableName: 'carts',
    timestamps: true,
    createdAt: false,
    underscored: true,
  });

  return Cart;
};
