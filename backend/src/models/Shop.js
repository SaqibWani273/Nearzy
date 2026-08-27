const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Shop = sequelize.define('Shop', {
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
    locationId: {
      type: DataTypes.BIGINT,
      allowNull: true,
      field: 'location_id',
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    slug: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false,
    },
    shopPicUrl: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'shop_pic_url',
    },
    phoneNumber: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false,
      field: 'phone_number',
    },
    address: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    isActive: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
      field: 'is_active',
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
    tableName: 'shops',
    timestamps: true,
    underscored: true,
  });

  return Shop;
};
