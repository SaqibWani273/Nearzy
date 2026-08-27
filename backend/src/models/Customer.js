const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Customer = sequelize.define('Customer', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    userId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      unique: true,
      field: 'user_id',
    },
    firstName: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'first_name',
    },
    lastName: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'last_name',
    },
    phoneNumber: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'phone_number',
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
    tableName: 'customers',
    timestamps: true,
    underscored: true,
  });

  return Customer;
};
