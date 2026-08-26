const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ProductCategory = sequelize.define('ProductCategory', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    name: {
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
      allowNull: true,
      field: 'is_top_category',
    },
    catSpecificMustAttributes: {
      type: DataTypes.TEXT,
      allowNull: true,
      field: 'cat_specific_must_attributes',
      get() {
        const raw = this.getDataValue('catSpecificMustAttributes');
        if (raw === null || raw === undefined) return null;
        try {
          return JSON.parse(raw);
        } catch (e) {
          return raw;
        }
      },
      set(val) {
        this.setDataValue('catSpecificMustAttributes', val ? JSON.stringify(val) : null);
      },
    },
    catSpecificOptionalAttributes: {
      type: DataTypes.TEXT,
      allowNull: true,
      field: 'cat_specific_optional_attributes',
      get() {
        const raw = this.getDataValue('catSpecificOptionalAttributes');
        if (raw === null || raw === undefined) return null;
        try {
          return JSON.parse(raw);
        } catch (e) {
          return raw;
        }
      },
      set(val) {
        this.setDataValue('catSpecificOptionalAttributes', val ? JSON.stringify(val) : null);
      },
    },
  }, {
    tableName: 'product_categories',
    timestamps: false,
  });

  return ProductCategory;
};
