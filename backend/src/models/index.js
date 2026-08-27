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

// Initialize Models
const NearzyUser = require('./NearzyUser')(sequelize);
const EmailConfirmation = require('./EmailConfirmation')(sequelize);
const Admin = require('./Admin')(sequelize);
const Customer = require('./Customer')(sequelize);
const Address = require('./Address')(sequelize);
const Cart = require('./Cart')(sequelize);
const CartItem = require('./CartItem')(sequelize);
const LocationInfo = require('./LocationInfo')(sequelize);
const Shop = require('./Shop')(sequelize);
const ShopVerification = require('./ShopVerification')(sequelize);
const ProductCategory = require('./ProductCategory')(sequelize);
const Product = require('./Product')(sequelize);
const ProductImage = require('./ProductImage')(sequelize);
const ProductColor = require('./ProductColor')(sequelize);
const Review = require('./Review')(sequelize);
const OrderRecord = require('./OrderRecord')(sequelize);
const OrderItem = require('./OrderItem')(sequelize);

// ============================
// Associations
// ============================

// 1. NearzyUser <-> EmailConfirmation (1:N)
EmailConfirmation.belongsTo(NearzyUser, { foreignKey: 'user_id', as: 'user' });
NearzyUser.hasMany(EmailConfirmation, { foreignKey: 'user_id', as: 'emailConfirmations' });

// 2. NearzyUser <-> Admin (1:1)
Admin.belongsTo(NearzyUser, { foreignKey: 'user_id', as: 'user' });
NearzyUser.hasOne(Admin, { foreignKey: 'user_id', as: 'admin' });

// 3. NearzyUser <-> Customer (1:1)
Customer.belongsTo(NearzyUser, { foreignKey: 'user_id', as: 'user' });
NearzyUser.hasOne(Customer, { foreignKey: 'user_id', as: 'customer' });

// 4. Customer <-> Address (1:N)
Address.belongsTo(Customer, { foreignKey: 'customer_id', as: 'customer' });
Customer.hasMany(Address, { foreignKey: 'customer_id', as: 'addresses' });

// 5. Customer <-> Cart (1:1)
Cart.belongsTo(Customer, { foreignKey: 'customer_id', as: 'customer' });
Customer.hasOne(Cart, { foreignKey: 'customer_id', as: 'cart' });

// 6. Cart <-> CartItem (1:N)
CartItem.belongsTo(Cart, { foreignKey: 'cart_id', as: 'cart' });
Cart.hasMany(CartItem, { foreignKey: 'cart_id', as: 'items' });

// 7. Product <-> CartItem (1:N)
CartItem.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
Product.hasMany(CartItem, { foreignKey: 'product_id', as: 'cartItems' });

// 8. NearzyUser <-> Shop (1:1)
Shop.belongsTo(NearzyUser, { foreignKey: 'user_id', as: 'user' });
NearzyUser.hasOne(Shop, { foreignKey: 'user_id', as: 'shop' });

// 9. Shop <-> LocationInfo (N:1)
Shop.belongsTo(LocationInfo, { foreignKey: 'location_id', as: 'locationInfo' });
LocationInfo.hasMany(Shop, { foreignKey: 'location_id', as: 'shops' });

// 10. Shop <-> ShopVerification (1:1)
ShopVerification.belongsTo(Shop, { foreignKey: 'shop_id', as: 'shop' });
Shop.hasOne(ShopVerification, { foreignKey: 'shop_id', as: 'verification' });

// 11. Admin <-> ShopVerification (1:N)
ShopVerification.belongsTo(Admin, { foreignKey: 'verified_by_admin_id', as: 'verifiedByAdmin' });
Admin.hasMany(ShopVerification, { foreignKey: 'verified_by_admin_id', as: 'verifiedShops' });

// 12. ProductCategory hierarchy (1:N self-ref)
ProductCategory.belongsTo(ProductCategory, { foreignKey: 'parent_id', as: 'parent' });
ProductCategory.hasMany(ProductCategory, { foreignKey: 'parent_id', as: 'children' });

// 13. Shop <-> ProductCategory (M:N)
Shop.belongsToMany(ProductCategory, { through: 'shop_categories', foreignKey: 'shop_id', otherKey: 'category_id', as: 'categories', timestamps: false });
ProductCategory.belongsToMany(Shop, { through: 'shop_categories', foreignKey: 'category_id', otherKey: 'shop_id', as: 'shops', timestamps: false });

// 14. Shop <-> Product (1:N)
Product.belongsTo(Shop, { foreignKey: 'shop_id', as: 'shop' });
Shop.hasMany(Product, { foreignKey: 'shop_id', as: 'products' });

// 15. ProductCategory <-> Product (1:N)
Product.belongsTo(ProductCategory, { foreignKey: 'category_id', as: 'category' });
ProductCategory.hasMany(Product, { foreignKey: 'category_id', as: 'products' });

// 16. Product <-> ProductImage (1:N)
ProductImage.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
Product.hasMany(ProductImage, { foreignKey: 'product_id', as: 'images' });

// 17. Product <-> ProductColor (1:N)
ProductColor.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
Product.hasMany(ProductColor, { foreignKey: 'product_id', as: 'colors' });

// 18. Product <-> Review (1:N)
Review.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
Product.hasMany(Review, { foreignKey: 'product_id', as: 'reviews' });

// 19. Customer <-> Review (1:N)
Review.belongsTo(Customer, { foreignKey: 'customer_id', as: 'customer' });
Customer.hasMany(Review, { foreignKey: 'customer_id', as: 'reviews' });

// 20. Customer <-> OrderRecord (1:N)
OrderRecord.belongsTo(Customer, { foreignKey: 'customer_id', as: 'customer' });
Customer.hasMany(OrderRecord, { foreignKey: 'customer_id', as: 'orders' });

// 21. Address <-> OrderRecord (1:N)
OrderRecord.belongsTo(Address, { foreignKey: 'shipping_address_id', as: 'shippingAddress' });
Address.hasMany(OrderRecord, { foreignKey: 'shipping_address_id', as: 'orders' });

// 22. OrderRecord <-> OrderItem (1:N)
OrderItem.belongsTo(OrderRecord, { foreignKey: 'order_id', as: 'order' });
OrderRecord.hasMany(OrderItem, { foreignKey: 'order_id', as: 'items' });

// 23. Product <-> OrderItem (1:N)
OrderItem.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
Product.hasMany(OrderItem, { foreignKey: 'product_id', as: 'orderItems' });

// 24. Shop <-> OrderItem (1:N)
OrderItem.belongsTo(Shop, { foreignKey: 'shop_id', as: 'shop' });
Shop.hasMany(OrderItem, { foreignKey: 'shop_id', as: 'orderItems' });

module.exports = {
  sequelize,
  NearzyUser,
  EmailConfirmation,
  Admin,
  Customer,
  Address,
  Cart,
  CartItem,
  LocationInfo,
  Shop,
  ShopVerification,
  ProductCategory,
  Product,
  ProductImage,
  ProductColor,
  Review,
  OrderRecord,
  OrderItem,
};
