const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ProductColor = sequelize.define('ProductColor', {
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
    colorName: {
      type: DataTypes.STRING,
      allowNull: false,
      field: 'color_name',
    },
    hexCode: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'hex_code',
    },
  }, {
    tableName: 'product_colors',
    timestamps: false,
    underscored: true,
  });

  return ProductColor;
};
