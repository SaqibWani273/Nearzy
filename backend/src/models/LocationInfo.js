const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const LocationInfo = sequelize.define('LocationInfo', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    shortAddress: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'short_address',
    },
    latitude: {
      type: DataTypes.DOUBLE,
      allowNull: false,
    },
    longitude: {
      type: DataTypes.DOUBLE,
      allowNull: false,
    },
    completeAddress: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'complete_address',
    },
    city: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    state: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    pincode: {
      type: DataTypes.STRING,
      allowNull: true,
    },
  }, {
    tableName: 'location_infos',
    timestamps: false,
    underscored: true,
  });

  return LocationInfo;
};
