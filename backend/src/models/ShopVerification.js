const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const ShopVerification = sequelize.define('ShopVerification', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    shopId: {
      type: DataTypes.BIGINT,
      allowNull: false,
      unique: true,
      field: 'shop_id',
    },
    ownerName: {
      type: DataTypes.STRING,
      allowNull: false,
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
    status: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'PENDING',
      validate: {
        isIn: [['PENDING', 'APPROVED', 'REJECTED']],
      },
    },
    verifiedByAdminId: {
      type: DataTypes.BIGINT,
      allowNull: true,
      field: 'verified_by_admin_id',
    },
    verifiedAt: {
      type: DataTypes.DATE,
      allowNull: true,
      field: 'verified_at',
    },
    submittedAt: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
      field: 'submitted_at',
    },
  }, {
    tableName: 'shop_verifications',
    timestamps: false,
    underscored: true,
  });

  return ShopVerification;
};
