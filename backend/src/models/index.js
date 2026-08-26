const { Sequelize } = require('sequelize');

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASS,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    dialect: 'postgres',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
  }
);

const MyUser = require('./MyUser')(sequelize);
const Customer = require('./Customer')(sequelize);
const Shop = require('./Shop')(sequelize);
const Admin = require('./Admin')(sequelize);
const Product = require('./Product')(sequelize);
const ProductCategory = require('./ProductCategory')(sequelize);
const LocationInfo = require('./LocationInfo')(sequelize);
const EmailConfirmation = require('./EmailConfirmation')(sequelize);

// Associations
// Customer belongs to MyUser (one-to-one)
Customer.belongsTo(MyUser, { foreignKey: 'user_id', as: 'myUser' });
MyUser.hasOne(Customer, { foreignKey: 'user_id', as: 'customer' });

// Shop belongs to MyUser (one-to-one)
Shop.belongsTo(MyUser, { foreignKey: 'user_id', as: 'myUser' });
MyUser.hasOne(Shop, { foreignKey: 'user_id', as: 'shop' });

// Shop belongs to LocationInfo (many-to-one)
Shop.belongsTo(LocationInfo, { foreignKey: 'location_id', as: 'locationInfo' });
LocationInfo.hasMany(Shop, { foreignKey: 'location_id', as: 'shops' });

// Admin belongs to MyUser (one-to-one)
Admin.belongsTo(MyUser, { foreignKey: 'user_id', as: 'myUser' });
MyUser.hasOne(Admin, { foreignKey: 'user_id', as: 'admin' });

// Product belongs to Shop (many-to-one)
Product.belongsTo(Shop, { foreignKey: 'shop_id', as: 'shop' });
Shop.hasMany(Product, { foreignKey: 'shop_id', as: 'products' });

// EmailConfirmation belongs to MyUser (one-to-one)
EmailConfirmation.belongsTo(MyUser, { foreignKey: 'user_id', as: 'myUser' });
MyUser.hasOne(EmailConfirmation, { foreignKey: 'user_id', as: 'emailConfirmation' });

module.exports = {
  sequelize,
  MyUser,
  Customer,
  Shop,
  Admin,
  Product,
  ProductCategory,
  LocationInfo,
  EmailConfirmation,
};
