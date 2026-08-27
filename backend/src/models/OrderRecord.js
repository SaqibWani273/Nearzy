const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const OrderRecord = sequelize.define('OrderRecord', {
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
    shippingAddressId: {
      type: DataTypes.BIGINT,
      allowNull: true,
      field: 'shipping_address_id',
    },
    orderNumber: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false,
      field: 'order_number',
    },
    status: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'PLACED',
      validate: {
        isIn: [['PLACED', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED']],
      },
    },
    paymentStatus: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'PENDING',
      field: 'payment_status',
      validate: {
        isIn: [['PENDING', 'PAID', 'FAILED', 'REFUNDED']],
      },
    },
    totalAmountPaise: {
      type: DataTypes.INTEGER,
      allowNull: false,
      field: 'total_amount_paise',
    },
    discountAmountPaise: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      field: 'discount_amount_paise',
    },
    placedAt: {
      type: DataTypes.DATE,
      field: 'placed_at',
    },
    updatedAt: {
      type: DataTypes.DATE,
      field: 'updated_at',
    },
  }, {
    tableName: 'order_records',
    timestamps: true,
    createdAt: 'placed_at',
    underscored: true,
  });

  return OrderRecord;
};
