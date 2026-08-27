const { NearzyUser, Customer, Product, Cart, CartItem, Address } = require('../models');
const authService = require('./authService');
const jwtService = require('./jwtService');

const customerService = {
  async registerCustomer(userData) {
    const result = await authService.preRegistrationProcess(userData);
    if (typeof result === 'string') {
      return { error: result, status: 400 };
    }

    userData.role = 'CUSTOMER';
    const user = await NearzyUser.create(userData);
    const customer = await Customer.create({ user_id: user.id });

    // Create initial cart for the customer
    await Cart.create({ customer_id: customer.id });

    const emailResult = await authService.sendVerificationEmail(user, 'customer/verify-email?token=');
    return emailResult;
  },

  async loginCustomer(email, password) {
    const user = await NearzyUser.findOne({ where: { email } });
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

    const user = await NearzyUser.findOne({ where: { email } });
    if (!user) return null;

    const customer = await Customer.findOne({
      where: { user_id: user.id },
      include: [
        { association: 'user' },
        {
          association: 'cart',
          include: [{ association: 'items', include: [{ association: 'product' }] }],
        },
        { association: 'addresses' },
      ],
    });
    return customer;
  },

  async getAllProducts() {
    const products = await Product.findAll({
      include: [
        { association: 'shop' },
        { association: 'category' },
        { association: 'images' },
        { association: 'colors' },
      ],
    });
    return products;
  },

  async updateCustomer(customerData) {
    if (!customerData.id) {
      return { error: 'Customer ID required', status: 400 };
    }

    const customer = await Customer.findByPk(customerData.id);
    if (!customer) {
      return { error: 'Customer not found', status: 400 };
    }

    // Update NearzyUser fields if provided
    if (customerData.user && customer.user_id) {
      await NearzyUser.update(customerData.user, { where: { id: customer.user_id } });
    }

    // Update Customer profile fields
    if (customerData.firstName !== undefined) customer.firstName = customerData.firstName;
    if (customerData.lastName !== undefined) customer.lastName = customerData.lastName;
    if (customerData.phoneNumber !== undefined) customer.phoneNumber = customerData.phoneNumber;

    await customer.save();

    const updated = await Customer.findByPk(customer.id, {
      include: [
        { association: 'user' },
        { association: 'addresses' },
        { association: 'cart' },
      ],
    });
    return updated;
  },

  async updateCartItems(customerId, cartItems) {
    let cart = await Cart.findOne({ where: { customer_id: customerId } });
    if (!cart) {
      cart = await Cart.create({ customer_id: customerId });
    }

    if (Array.isArray(cartItems)) {
      for (const item of cartItems) {
        const productId = item.productId || item.product_id;
        const quantity = item.quantity;

        if (!productId) continue;

        if (quantity <= 0) {
          await CartItem.destroy({
            where: {
              cart_id: cart.id,
              product_id: productId,
            },
          });
        } else {
          const [cartItem, created] = await CartItem.findOrCreate({
            where: { cart_id: cart.id, product_id: productId },
            defaults: { quantity, added_at: new Date() },
          });

          if (!created) {
            cartItem.quantity = quantity;
            await cartItem.save();
          }
        }
      }
    }

    cart.changed('updatedAt', true);
    await cart.save();

    return { message: 'Cart Items Updated' };
  },

  async fetchProductsByIds(ids) {
    const products = await Product.findAll({
      where: { id: ids },
      include: [
        { association: 'shop' },
        { association: 'category' },
        { association: 'images' },
        { association: 'colors' },
      ],
    });
    return products;
  },
};

module.exports = customerService;
