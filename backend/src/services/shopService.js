const { MyUser, Shop, Product, LocationInfo } = require('../models');
const authService = require('./authService');
const jwtService = require('./jwtService');

const shopService = {
  async registerShop(shopData) {
    const userData = shopData.myUser;
    if (!userData) {
      return { error: 'User data is required', status: 400 };
    }

    const result = await authService.preRegistrationProcess(userData);
    if (typeof result === 'string') {
      return { error: result, status: 400 };
    }

    userData.roles = 'SHOP';
    const user = await MyUser.create(userData);

    // Create LocationInfo if provided
    let locationId = null;
    if (shopData.locationInfo) {
      const location = await LocationInfo.create(shopData.locationInfo);
      locationId = location.id;
    }

    await Shop.create({
      user_id: user.id,
      isVerifiedByAdmin: false,
      shopPicUrl: shopData.shopPicUrl,
      phoneNumber: shopData.phoneNumber,
      address: shopData.address,
      description: shopData.description,
      createDate: new Date(),
      ownerName: shopData.ownerName,
      ownerPicUrl: shopData.ownerPicUrl,
      pancardPicUrl: shopData.pancardPicUrl,
      ownerIdPicUrl: shopData.ownerIdPicUrl,
      businessLicense: shopData.businessLicense,
      categories: shopData.categories,
      location_id: locationId,
    });

    const emailResult = await authService.sendVerificationEmail(user, 'shop/verify-email?token=');
    return emailResult;
  },

  async loginShop(email, password) {
    const user = await MyUser.findOne({ where: { email } });
    if (!user) {
      return { error: 'Email Not Registered', status: 400 };
    }
    if (!user.isEmailVerified) {
      return { error: 'Email not verified', status: 400 };
    }
    if (user.roles !== 'SHOP') {
      return { error: 'Not a shop user', status: 400 };
    }
    return authService.authenticateAndGenerateToken(email, password);
  },

  async verifyEmail(token) {
    return authService.verifyEmail(token);
  },

  async getShop(token) {
    const email = jwtService.extractEmail(token);
    if (!email) {
      return { error: 'Invalid token', status: 400 };
    }
    const user = await MyUser.findOne({ where: { email } });
    if (!user) {
      return { error: 'User not found', status: 400 };
    }
    const shop = await Shop.findOne({
      where: { user_id: user.id },
      include: [
        { association: 'myUser' },
        { association: 'locationInfo' },
      ],
    });
    return shop;
  },

  async addProduct(productData) {
    console.log('adding product', productData);
    const product = await Product.create(productData);
    return { message: `Product Added -> ${JSON.stringify(product)}` };
  },
};

module.exports = shopService;
