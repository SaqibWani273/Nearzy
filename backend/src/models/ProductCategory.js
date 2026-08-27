const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ProductCategory = sequelize.define('ProductCategory', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    parentId: {
      type: DataTypes.BIGINT,
      allowNull: true,
      field: 'parent_id',
    },
    name: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false,
    },
    slug: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false,
    },
    imageUrl: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'image_url',
    },
    description: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    isTopCategory: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      field: 'is_top_category',
    },
    displayOrder: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      field: 'display_order',
    },
    requiredAttributes: {
      type: DataTypes.JSON,
      allowNull: true,
      field: 'required_attributes',
    },
    optionalAttributes: {
      type: DataTypes.JSON,
      allowNull: true,
      field: 'optional_attributes',
    },
  }, {
    tableName: 'product_categories',
    timestamps: false,
    underscored: true,
  });

  return ProductCategory;
};
