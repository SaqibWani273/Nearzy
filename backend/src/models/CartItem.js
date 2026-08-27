const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const CartItem = sequelize.define('CartItem', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    cartId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'cart_id',
    },
    productId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'product_id',
    },
    quantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1,
    },
    addedAt: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
      field: 'added_at',
    },
  }, {
    tableName: 'cart_items',
    timestamps: false,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['cart_id', 'product_id'],
        name: 'idx_cart_product_unique',
      },
    ],
  });

  return CartItem;
};
