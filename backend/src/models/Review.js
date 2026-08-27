const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Review = sequelize.define('Review', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    productId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'product_id',
    },
    customerId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'customer_id',
    },
    rating: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: 1,
        max: 5,
      },
    },
    title: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    body: {
      type: DataTypes.TEXT,
      allowNull: true,
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
    tableName: 'reviews',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['product_id', 'customer_id'],
        name: 'idx_one_review_per_customer',
      },
    ],
  });

  return Review;
};
