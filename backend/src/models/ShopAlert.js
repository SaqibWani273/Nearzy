const { DataTypes } = require('sequelize');

/**
 * A thing the shop owner should do something about.
 *
 * The operator surfaces were previously all pull: the owner had to go looking
 * for a stockout. Alerts invert that — background jobs write rows here and the
 * dashboard renders them as a triage list, so opening the app tells you what
 * needs attention rather than handing you an empty form.
 *
 * Deliberately not a notifications table: there is no delivery, no read
 * receipt across devices, no push. It is durable state about the shop, and the
 * dashboard is the only reader.
 */
module.exports = (sequelize) => {
  const ShopAlert = sequelize.define('ShopAlert', {
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
    // Null for alerts about the shop as a whole rather than one item.
    productId: {
      type: DataTypes.BIGINT,
      allowNull: true,
      field: 'product_id',
    },
    type: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        isIn: [['LOW_STOCK', 'STOCKOUT', 'MARKDOWN_APPLIED']],
      },
    },
    severity: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'INFO',
      validate: {
        isIn: [['INFO', 'WARNING', 'CRITICAL']],
      },
    },
    title: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    body: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    status: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'UNREAD',
      validate: {
        isIn: [['UNREAD', 'READ', 'RESOLVED']],
      },
    },
    resolvedAt: {
      type: DataTypes.DATE,
      allowNull: true,
      field: 'resolved_at',
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
    tableName: 'shop_alerts',
    timestamps: true,
    underscored: true,
    indexes: [
      // The dashboard's only query: this shop's open alerts, newest first.
      {
        fields: ['shop_id', 'status'],
        name: 'idx_shop_alert_shop_status',
      },
      // The replenishment job reruns hourly and must find the alert it already
      // raised for a product instead of writing a twenty-fifth copy of it.
      {
        fields: ['shop_id', 'product_id', 'type', 'status'],
        name: 'idx_shop_alert_dedupe',
      },
    ],
  });

  return ShopAlert;
};
