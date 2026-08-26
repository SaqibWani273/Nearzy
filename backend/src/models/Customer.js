const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Customer = sequelize.define('Customer', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    cartItems: {
      type: DataTypes.TEXT,
      allowNull: true,
      field: 'cart_items',
      get() {
        const raw = this.getDataValue('cartItems');
        if (raw === null || raw === undefined) return null;
        try {
          return JSON.parse(raw);
        } catch (e) {
          return raw;
        }
      },
      set(val) {
        this.setDataValue('cartItems', val ? JSON.stringify(val) : null);
      },
    },
  }, {
    tableName: 'customers',
    timestamps: false,
  });

  return Customer;
};
