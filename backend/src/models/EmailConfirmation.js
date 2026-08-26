const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const EmailConfirmation = sequelize.define('EmailConfirmation', {
    id: {
      type: DataTypes.BIGINT,
      primaryKey: true,
      autoIncrement: true,
    },
    token: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false,
    },
    createDate: {
      type: DataTypes.DATE,
      allowNull: true,
      field: 'create_date',
    },
  }, {
    tableName: 'email_confirmations',
    timestamps: false,
  });

  return EmailConfirmation;
};
