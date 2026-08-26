const { MyUser, Customer, Product } = require('../models');
const authService = require('./authService');
const jwtService = require('./jwtService');

const customerService = {
  async registerCustomer(userData) {
    const result = await authService.preRegistrationProcess(userData);
    if (typeof result === 'string') {
      return { error: result, status: 400 };
    }

    userData.roles = 'CUSTOMER';
    const user = await MyUser.create(userData);
    await Customer.create({ user_id: user.id });

    const emailResult = await authService.sendVerificationEmail(user, 'customer/verify-email?token=');
    return emailResult;
  },

  async loginCustomer(email, password) {
    const user = await MyUser.findOne({ where: { email } });
    if (!user) {
      return { error: 'Email Not Registered', status: 400 };
    }
    if (!user.isEmailVerified) {
      return { error: 'Email not verified', status: 400 };
    }
    return authService.authenticateAndGenerateToken(email, password);
  },

  async verifyEmail(token) {
    return authService.verifyEmail(token);
  },

  async getCustomer(token) {
    const email = jwtService.extractEmail(token);
    if (!email) return null;

    const user = await MyUser.findOne({ where: { email } });
    if (!user) return null;

    const customer = await Customer.findOne({
      where: { user_id: user.id },
      include: [{ association: 'myUser' }],
    });
    return customer;
  },

  async getAllProducts() {
    const products = await Product.findAll({
      include: [{ association: 'shop' }],
    });
    return products;
  },

  async updateCustomer(customerData) {
    // If customer has an id, update it
    if (customerData.id) {
      const customer = await Customer.findByPk(customerData.id);
      if (!customer) {
        return { error: 'Customer not found', status: 400 };
      }
      // Update myUser if provided
      if (customerData.myUser && customer.user_id) {
        await MyUser.update(customerData.myUser, { where: { id: customer.user_id } });
      }
      if (customerData.cartItems !== undefined) {
        customer.cartItems = customerData.cartItems;
      }
      await customer.save();
      const updated = await Customer.findByPk(customer.id, {
        include: [{ association: 'myUser' }],
      });
      return updated;
    }
    return { error: 'Customer ID required', status: 400 };
  },

  async updateCartItems(customerId, cartItems) {
    const customer = await Customer.findByPk(customerId);
    if (!customer) {
      return { error: 'Customer not found', status: 400 };
    }
    customer.cartItems = cartItems;
    await customer.save();
    return { message: 'Cart Items Updated' };
  },

  async fetchProductsByIds(ids) {
    const products = await Product.findAll({
      where: { id: ids },
    });
    return products;
  },
};

module.exports = customerService;
