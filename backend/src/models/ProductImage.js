const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ProductImage = sequelize.define('ProductImage', {
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
    url: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    displayOrder: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      field: 'display_order',
    },
    isPrimary: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      field: 'is_primary',
    },
  }, {
    tableName: 'product_images',
    timestamps: false,
    underscored: true,
  });

  return ProductImage;
};
