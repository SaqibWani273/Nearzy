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
    // Stamped when the stockout hook below pulled the product, and cleared when
    // it puts it back. Its presence is what separates "we hid this because it
    // ran out" from "the owner hid this deliberately" — only the former is
    // eligible to be republished automatically.
    autoUnpublishedAt: {
      type: DataTypes.DATE,
      allowNull: true,
      field: 'auto_unpublished_at',
    },
    // Opt-in, per product: the markdown engine never touches a product the
    // owner has not enrolled, because it is rewriting a price they set.
    markdownEnabled: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      field: 'markdown_enabled',
    },
    // The deepest discount the engine may reach. 0 leaves it no room to move.
    markdownFloorPercent: {
      type: DataTypes.DOUBLE,
      defaultValue: 0,
      field: 'markdown_floor_percent',
    },
    // The owner's own standing discount. The midnight reset restores this
    // rather than zeroing `discountPercent`, which would quietly delete a
    // permanent markdown the owner had configured by hand.
    baseDiscountPercent: {
      type: DataTypes.DOUBLE,
      defaultValue: 0,
      field: 'base_discount_percent',
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
    hooks: {
      /**
       * Stock and availability are kept consistent here rather than at each
       * call site, so a product can never be listed to customers with nothing
       * behind it — whoever wrote the stock, and for whatever reason.
       *
       * `beforeSave` covers `create()` and instance `.save()`. It does NOT run
       * for `Model.update({}, { where })` or `.decrement()`, which bypass
       * instance hooks entirely. Every stock write in this codebase therefore
       * goes through an instance save; if you add one that cannot, pass
       * `individualHooks: true`.
       */
      beforeSave(product) {
        if (product.stockQuantity <= 0 && product.available) {
          product.available = false;
          product.autoUnpublishedAt = new Date();
        } else if (
          product.stockQuantity > 0 &&
          !product.available &&
          product.autoUnpublishedAt
        ) {
          // Only republish what we pulled ourselves. A product the owner
          // unpublished by hand carries no stamp, and restocking it must not
          // override that decision.
          product.available = true;
          product.autoUnpublishedAt = null;
        }
      },
    },
  });

  return Product;
};
