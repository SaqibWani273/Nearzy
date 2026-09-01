const { NearzyUser, Customer, Product, Cart, CartItem, Address, Shop, LocationInfo, ProductCategory, ProductImage, ProductColor } = require('../models');
const authService = require('./authService');
const jwtService = require('./jwtService');
const { Op, literal } = require('sequelize');

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

  /** Maps an authenticated NearzyUser id to its Customer row id. */
  async getCustomerIdByUserId(userId) {
    const customer = await Customer.findOne({ where: { user_id: userId } });
    return customer ? customer.id : null;
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

  // ---------------------------------------------------------------------------
  // Location-based discovery
  // ---------------------------------------------------------------------------

  /**
   * Build a Sequelize `where` clause for LocationInfo based on the supplied
   * location params.  Supports:
   *   - city / state / pincode  → ILIKE text match
   *   - latitude + longitude + radiusKm → Haversine radius (raw SQL literal)
   */
  _buildLocationWhere({ city, state, pincode, latitude, longitude, radiusKm = 10 }) {
    const where = {};
    const hasCityFilter = city || state || pincode;
    const hasGeoFilter = latitude != null && longitude != null;

    if (!hasCityFilter && !hasGeoFilter) {
      return null; // no filter — caller decides how to handle
    }

    if (city)    where.city    = { [Op.iLike]: `%${city}%` };
    if (state)   where.state   = { [Op.iLike]: `%${state}%` };
    if (pincode) where.pincode = { [Op.iLike]: `%${pincode}%` };

    if (hasGeoFilter) {
      // Haversine formula (distance in km between two lat-lng points)
      const lat  = parseFloat(latitude);
      const lng  = parseFloat(longitude);
      const r    = parseFloat(radiusKm) || 10;
      where[Op.and] = where[Op.and] || [];
      where[Op.and].push(
        literal(
          `(6371 * acos(
              cos(radians(${lat})) * cos(radians(latitude))
              * cos(radians(longitude) - radians(${lng}))
              + sin(radians(${lat})) * sin(radians(latitude))
          )) <= ${r}`
        )
      );
    }

    return where;
  },

  /**
   * GET /customer/shops-near-location
   * Returns paginated active shops whose LocationInfo matches the supplied
   * city/state/pincode or falls within `radiusKm` of lat-lng.
   */
  async getShopsNearLocation({ city, state, pincode, latitude, longitude, radiusKm = 10, page = 1, limit = 20 }) {
    const locationWhere = this._buildLocationWhere({ city, state, pincode, latitude, longitude, radiusKm });

    const offset = (parseInt(page) - 1) * parseInt(limit);

    const shopQuery = {
      where: { isActive: true },
      include: [
        {
          association: 'locationInfo',
          ...(locationWhere ? { where: locationWhere, required: true } : {}),
        },
        { association: 'categories' },
        { association: 'verification' },
      ],
      limit: parseInt(limit),
      offset,
      order: [['name', 'ASC']],
    };

    const { count, rows: shops } = await Shop.findAndCountAll(shopQuery);

    return {
      total: count,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages: Math.ceil(count / parseInt(limit)),
      shops,
    };
  },

  /**
   * GET /customer/location-specialities
   * Builds a discovery feed for a given location.  Returns an array of
   * "sections" — each section is a thematic group of local products:
   *
   *   1. One section per top local category (e.g. "Kashmiri Kehwa & Tea")
   *      with the top-5 products from shops in that area.
   *   2. An "Affordable Finds" section with the 10 cheapest available products.
   */
  async getLocationSpecialities({ city, state, pincode, latitude, longitude, radiusKm = 10 }) {
    const locationWhere = this._buildLocationWhere({ city, state, pincode, latitude, longitude, radiusKm });

    // 1. Find shop IDs in this area
    const shops = await Shop.findAll({
      where: { isActive: true },
      attributes: ['id'],
      include: locationWhere
        ? [{ association: 'locationInfo', where: locationWhere, required: true, attributes: [] }]
        : [],
    });

    if (!shops.length) {
      return { location: { city, state, pincode }, sections: [] };
    }

    const shopIds = shops.map((s) => s.id);

    // 2. Find categories that have products from these shops
    const categories = await ProductCategory.findAll({
      include: [
        {
          association: 'products',
          where: { shop_id: shopIds, available: true },
          required: true,
          include: [
            { association: 'images' },
            { association: 'colors' },
            {
              association: 'shop',
              include: [{ association: 'locationInfo' }],
            },
          ],
          limit: 5,
          order: [['avg_rating', 'DESC']],
        },
      ],
      order: [['display_order', 'ASC']],
    });

    // 3. Build spotlight sections per category
    const sections = categories
      .filter((cat) => cat.products && cat.products.length > 0)
      .slice(0, 6) // cap at 6 spotlight sections
      .map((cat) => ({
        sectionTitle: cat.name,
        sectionSubtitle: cat.description || `Top picks in ${cat.name}`,
        type: 'CATEGORY_SPOTLIGHT',
        categoryId: cat.id,
        categorySlug: cat.slug,
        products: cat.products,
      }));

    // 4. Affordable finds section (cheapest 10 available products in the area)
    const affordableProducts = await Product.findAll({
      where: { shop_id: shopIds, available: true },
      include: [
        { association: 'images' },
        { association: 'colors' },
        { association: 'category' },
        {
          association: 'shop',
          include: [{ association: 'locationInfo' }],
        },
      ],
      order: [['price_in_paise', 'ASC']],
      limit: 10,
    });

    if (affordableProducts.length > 0) {
      sections.unshift({
        sectionTitle: 'Best Affordable Finds Nearby',
        sectionSubtitle: 'Great products at pocket-friendly prices',
        type: 'AFFORDABLE',
        products: affordableProducts,
      });
    }

    const locationLabel = city || state || pincode || 'Your Area';
    return {
      location: { city, state, pincode, latitude, longitude },
      locationLabel,
      sections,
    };
  },

  /**
   * GET /customer/affordable-products
   * Returns cheapest-first available products from shops in the given location.
   * Optionally cap by `maxPriceInPaise`.
   */
  async getAffordableProductsByLocation({ city, state, pincode, latitude, longitude, radiusKm = 10, maxPriceInPaise, page = 1, limit = 20 }) {
    const locationWhere = this._buildLocationWhere({ city, state, pincode, latitude, longitude, radiusKm });

    const shops = await Shop.findAll({
      where: { isActive: true },
      attributes: ['id'],
      include: locationWhere
        ? [{ association: 'locationInfo', where: locationWhere, required: true, attributes: [] }]
        : [],
    });

    if (!shops.length) {
      return { total: 0, page: parseInt(page), limit: parseInt(limit), totalPages: 0, products: [] };
    }

    const shopIds = shops.map((s) => s.id);
    const productWhere = { shop_id: shopIds, available: true };
    if (maxPriceInPaise) {
      productWhere.price_in_paise = { [Op.lte]: parseInt(maxPriceInPaise) };
    }

    const offset = (parseInt(page) - 1) * parseInt(limit);

    const { count, rows: products } = await Product.findAndCountAll({
      where: productWhere,
      include: [
        { association: 'images' },
        { association: 'colors' },
        { association: 'category' },
        {
          association: 'shop',
          include: [{ association: 'locationInfo' }],
        },
      ],
      order: [['price_in_paise', 'ASC']],
      limit: parseInt(limit),
      offset,
    });

    return {
      total: count,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages: Math.ceil(count / parseInt(limit)),
      products,
    };
  },
};

module.exports = customerService;

