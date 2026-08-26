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
      allowNull: true,
    },
    longitude: {
      type: DataTypes.DOUBLE,
      allowNull: true,
      field: 'longtitude',
    },
    completeAddress: {
      type: DataTypes.STRING,
      allowNull: true,
      field: 'complete_address',
    },
  }, {
    tableName: 'location_infos',
    timestamps: false,
  });

  return LocationInfo;
};
