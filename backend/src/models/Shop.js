const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Shop = sequelize.define('Shop', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    isVerifiedByAdmin: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      field: 'is_verified_by_admin',
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
      type: DataTypes.STRING,
      allowNull: true,
    },
    createDate: {
      type: DataTypes.DATE,
      allowNull: true,
      field: 'create_date',
    },
    ownerName: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'owner_name',
    },
    ownerPicUrl: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'owner_pic_url',
    },
    pancardPicUrl: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'pancard_pic_url',
    },
    ownerIdPicUrl: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'owner_id_pic_url',
    },
    businessLicense: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'business_license',
    },
    categories: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      allowNull: true,
    },
  }, {
    tableName: 'shops',
    timestamps: false,
  });

  return Shop;
};
