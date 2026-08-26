const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Product = sequelize.define('Product', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    brand: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    shortDescription: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'short_description',
    },
    images: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      allowNull: true,
    },
    price: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    discountInPercentage: {
      type: DataTypes.DOUBLE,
      allowNull: true,
      field: 'discount_in_percentage',
    },
    completeDescription: {
      type: DataTypes.TEXT,
      allowNull: true,
      field: 'complete_description',
    },
    stockQuantity: {
      type: DataTypes.INTEGER,
      allowNull: true,
      field: 'stock_quantity',
    },
    rating: {
      type: DataTypes.DOUBLE,
      allowNull: true,
    },
    category: {
      type: DataTypes.TEXT,
      allowNull: true,
      get() {
        const raw = this.getDataValue('category');
        if (raw === null || raw === undefined) return null;
        try {
          return JSON.parse(raw);
        } catch (e) {
          return raw;
        }
      },
      set(val) {
        this.setDataValue('category', val ? JSON.stringify(val) : null);
      },
    },
    colors: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      allowNull: true,
    },
    available: {
      type: DataTypes.BOOLEAN,
      allowNull: true,
    },
    sku: {
      type: DataTypes.STRING,
      allowNull: true,
    },
  }, {
    tableName: 'products',
    timestamps: false,
  });

  return Product;
};
