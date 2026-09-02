const { sequelize, NearzyUser, Customer, Product, Cart, CartItem, Address, Shop, LocationInfo, ProductCategory, ProductImage, ProductColor } = require('../models');
const authService = require('./authService');
const jwtService = require('./jwtService');
const { Op, literal } = require('sequelize');
const { toProductDto, toShopDto } = require('../dto/productDto');

/** Single-quote escaping for values interpolated into a raw SQL literal. */
const sequelizeEscape = (value) => `'${String(value).replace(/'/g, "''")}'`;

const customerService = {
  async registerCustomer(userData) {
    const result = await authService.preRegistrationProcess(userData);
    if (typeof result === 'string') {
      return { error: result, status: 400 };
    }

    userData.role = 'CUSTOMER';
    // One transaction: a failure part-way through must not leave a NearzyUser
    // without its Customer/Cart rows, which would permanently block that email
    // from registering again.
    const user = await sequelize.transaction(async (transaction) => {
      const createdUser = await NearzyUser.create(userData, { transaction });
      const customer = await Customer.create({ userId: createdUser.id }, { transaction });
      await Cart.create({ customerId: customer.id }, { transaction });
      return createdUser;
    });

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

  /**
   * Returns one page of products in the shape the Flutter client expects.
   *
   * `page` is 0-based: the client's PagingController starts at 0 and stops
   * once a page comes back shorter than pageSize, so the offset must advance
   * or it would re-request the same rows forever.
   */
  async getAllProducts({ page = 0, pageSize = 10 } = {}) {
    const parsedSize = Number.parseInt(pageSize, 10);
    const parsedPage = Number.parseInt(page, 10);
    const limit = Math.min(Math.max(Number.isNaN(parsedSize) ? 10 : parsedSize, 1), 100);
    const offset = Math.max(Number.isNaN(parsedPage) ? 0 : parsedPage, 0) * limit;

    const products = await Product.findAll({
      include: this._productIncludes(),
      order: [['id', 'ASC']],
      limit,
      offset,
    });
    return products.map(toProductDto);
  },

  /**
   * The include tree every product listing needs. Factored out because the
   * shape has to stay identical across endpoints — the client's Product model
   * casts several of these associations unconditionally.
   */
  _productIncludes() {
    return [
      {
        association: 'shop',
        include: [
          // Never load the hash; the DTO drops it, but it should not travel at all.
          { association: 'user', attributes: { exclude: ['passwordHash'] } },
          { association: 'locationInfo' },
          { association: 'verification' },
          { association: 'categories' },
        ],
      },
      { association: 'category' },
      { association: 'images' },
      { association: 'colors' },
    ];
  },

  /** Normalises page/limit and returns Sequelize's limit/offset pair. */
  _paging({ page = 1, limit = 20, zeroBased = false } = {}) {
    const parsedLimit = Number.parseInt(limit, 10);
    const parsedPage = Number.parseInt(page, 10);
    const safeLimit = Math.min(Math.max(Number.isNaN(parsedLimit) ? 20 : parsedLimit, 1), 100);
    const rawPage = Math.max(Number.isNaN(parsedPage) ? (zeroBased ? 0 : 1) : parsedPage, zeroBased ? 0 : 1);
    const pageIndex = zeroBased ? rawPage : rawPage - 1;
    return { limit: safeLimit, offset: pageIndex * safeLimit, page: rawPage };
  },

  /**
   * GET /customer/shops/:shopId/products
   * A single shop's catalogue. Without this the shop detail screen had no
   * source of products at all and always rendered its empty state.
   */
  async getProductsByShop(shopId, { page, limit, includeUnavailable = false } = {}) {
    const id = Number.parseInt(shopId, 10);
    if (Number.isNaN(id)) return { error: 'Invalid shop id', status: 400 };

    const paging = this._paging({ page, limit });
    const where = { shop_id: id };
    if (!includeUnavailable) where.available = true;

    const { count, rows } = await Product.findAndCountAll({
      where,
      include: this._productIncludes(),
      order: [['avg_rating', 'DESC'], ['id', 'ASC']],
      limit: paging.limit,
      offset: paging.offset,
      // findAndCountAll over hasMany includes counts join rows, not products.
      distinct: true,
    });

    return {
      total: count,
      page: paging.page,
      limit: paging.limit,
      totalPages: Math.ceil(count / paging.limit),
      products: rows.map(toProductDto),
    };
  },

  /**
   * GET /customer/products-by-category/:categoryId
   * Includes descendant categories, so browsing "Shawls & Wraps" also
   * surfaces products filed under "Pashmina Shawls".
   */
  async getProductsByCategory(categoryId, { page, limit, latitude, longitude, radiusKm } = {}) {
    const id = Number.parseInt(categoryId, 10);
    if (Number.isNaN(id)) return { error: 'Invalid category id', status: 400 };

    const children = await ProductCategory.findAll({
      where: { parent_id: id },
      attributes: ['id'],
    });
    const categoryIds = [id, ...children.map((c) => c.id)];

    const paging = this._paging({ page, limit });
    const shopFilter = await this._shopIdsNearLocation({ latitude, longitude, radiusKm });

    const where = { category_id: categoryIds, available: true };
    if (shopFilter) where.shop_id = shopFilter;

    const { count, rows } = await Product.findAndCountAll({
      where,
      include: this._productIncludes(),
      order: [['avg_rating', 'DESC'], ['id', 'ASC']],
      limit: paging.limit,
      offset: paging.offset,
      distinct: true,
    });

    return {
      total: count,
      page: paging.page,
      limit: paging.limit,
      totalPages: Math.ceil(count / paging.limit),
      products: rows.map(toProductDto),
    };
  },

  /**
   * GET /customer/search-products
   * Matches name, brand, SKU and description, and can be scoped to shops
   * near a coordinate so search respects the location the user is browsing.
   */
  async searchProducts({ q, page, limit, latitude, longitude, radiusKm } = {}) {
    const term = (q || '').trim();
    if (term.length < 2) {
      return { total: 0, page: 1, limit: 0, totalPages: 0, products: [] };
    }

    const paging = this._paging({ page, limit });
    const like = { [Op.iLike]: `%${term}%` };

    const where = {
      available: true,
      [Op.or]: [
        { name: like },
        { brand: like },
        { sku: like },
        { shortDescription: like },
      ],
    };

    const shopFilter = await this._shopIdsNearLocation({ latitude, longitude, radiusKm });
    if (shopFilter) where.shop_id = shopFilter;

    const { count, rows } = await Product.findAndCountAll({
      where,
      include: this._productIncludes(),
      // Exact prefix matches first, then by rating.
      order: [
        [literal(`CASE WHEN "Product"."name" ILIKE ${sequelizeEscape(`${term}%`)} THEN 0 ELSE 1 END`), 'ASC'],
        ['avg_rating', 'DESC'],
      ],
      limit: paging.limit,
      offset: paging.offset,
      distinct: true,
    });

    return {
      total: count,
      page: paging.page,
      limit: paging.limit,
      totalPages: Math.ceil(count / paging.limit),
      products: rows.map(toProductDto),
    };
  },

  /**
   * GET /customer/discounted-products
   * Products currently on discount in the customer's area, deepest cut first.
   */
  async getDiscountedProducts({ page, limit, latitude, longitude, radiusKm, minPercent = 1 } = {}) {
    const paging = this._paging({ page, limit });
    const shopFilter = await this._shopIdsNearLocation({ latitude, longitude, radiusKm });

    const where = {
      available: true,
      discountPercent: { [Op.gte]: parseFloat(minPercent) || 1 },
    };
    if (shopFilter) where.shop_id = shopFilter;

    const { count, rows } = await Product.findAndCountAll({
      where,
      include: this._productIncludes(),
      order: [['discount_percent', 'DESC'], ['avg_rating', 'DESC']],
      limit: paging.limit,
      offset: paging.offset,
      distinct: true,
    });

    return {
      total: count,
      page: paging.page,
      limit: paging.limit,
      totalPages: Math.ceil(count / paging.limit),
      products: rows.map(toProductDto),
    };
  },

  /**
   * Shop ids within the given radius, or null when no coordinates were
   * supplied (meaning "don't filter by location").
   */
  async _shopIdsNearLocation({ latitude, longitude, radiusKm }) {
    if (latitude == null || longitude == null) return null;

    const locationWhere = this._buildLocationWhere({ latitude, longitude, radiusKm });
    if (!locationWhere) return null;

    const shops = await Shop.findAll({
      where: { isActive: true },
      attributes: ['id'],
      include: [
        {
          association: 'locationInfo',
          where: locationWhere,
          required: true,
          attributes: [],
        },
      ],
    });
    // An empty array is meaningful — it means "nothing nearby", which must
    // narrow the query rather than being ignored.
    return shops.map((s) => s.id);
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
    if (customerData.user && customer.userId) {
      await NearzyUser.update(customerData.user, { where: { id: customer.userId } });
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
    let cart = await Cart.findOne({ where: { customerId } });
    if (!cart) {
      cart = await Cart.create({ customerId });
    }

    if (Array.isArray(cartItems)) {
      for (const item of cartItems) {
        const productId = item.productId || item.product_id;
        const quantity = item.quantity;

        if (!productId) continue;

        if (quantity <= 0) {
          await CartItem.destroy({
            where: {
              cartId: cart.id,
              productId,
            },
          });
        } else {
          const [cartItem, created] = await CartItem.findOrCreate({
            where: { cartId: cart.id, productId },
            defaults: { quantity, addedAt: new Date() },
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

    // Raw ORM rows leak column names and the password hash, and omit the
    // shop's trading name entirely — always go through the DTO.
    const origin =
      latitude != null && longitude != null
        ? { latitude: parseFloat(latitude), longitude: parseFloat(longitude) }
        : null;

    const dtos = shops.map((shop) => toShopDto(shop, origin));

    // With a coordinate to measure from, nearest-first beats alphabetical.
    // Sorting here rather than in SQL keeps the Haversine expression in one
    // place; the page is at most `limit` rows, so the cost is negligible.
    if (origin) {
      dtos.sort((a, b) => (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity));
    }

    return {
      total: count,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages: Math.ceil(count / parseInt(limit)),
      shops: dtos,
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

