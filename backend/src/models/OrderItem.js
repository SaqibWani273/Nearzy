const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const OrderItem = sequelize.define('OrderItem', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    orderId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'order_id',
    },
    productId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'product_id',
    },
    shopId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'shop_id',
    },
    quantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1,
    },
    unitPricePaise: {
      type: DataTypes.INTEGER,
      allowNull: false,
      field: 'unit_price_paise',
    },
    discountPaise: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      field: 'discount_paise',
    },
  }, {
    tableName: 'order_items',
    timestamps: false,
    underscored: true,
  });

  return OrderItem;
};
