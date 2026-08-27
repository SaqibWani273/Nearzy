const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Product = sequelize.define('Product', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    shopId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'shop_id',
    },
    categoryId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      field: 'category_id',
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    brand: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    sku: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: true,
    },
    shortDescription: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'short_description',
    },
    completeDescription: {
      type: DataTypes.TEXT,
      allowNull: true,
      field: 'complete_description',
    },
    priceInPaise: {
      type: DataTypes.INTEGER,
      allowNull: false,
      field: 'price_in_paise',
    },
    discountPercent: {
      type: DataTypes.DOUBLE,
      defaultValue: 0,
      field: 'discount_percent',
    },
    stockQuantity: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      field: 'stock_quantity',
    },
    available: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    avgRating: {
      type: DataTypes.DOUBLE,
      defaultValue: 0,
      field: 'avg_rating',
    },
    reviewCount: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      field: 'review_count',
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
    tableName: 'products',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        fields: ['shop_id', 'name'],
        name: 'idx_product_shop_name',
      },
      {
        fields: ['brand'],
        name: 'idx_product_brand',
      },
    ],
  });

  return Product;
};
