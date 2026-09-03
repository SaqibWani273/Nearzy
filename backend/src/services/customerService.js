const { sequelize, NearzyUser, Customer, Product, Cart, CartItem, Address, Shop, LocationInfo, ProductCategory, ProductImage, ProductColor, OrderRecord } = require('../models');
const authService = require('./authService');
const jwtService = require('./jwtService');
const { Op, literal } = require('sequelize');
const { toProductDto, toShopDto } = require('../dto/productDto');
const { toAddressDto } = require('../dto/orderDto');
// Aliased: several methods here declare a local `const paging = this._paging(...)`,
// which would otherwise shadow this import.
const { paging: normalisePaging } = require('../utils/paging');

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

  async loginCustomer(email, password, meta = {}) {
    const user = await NearzyUser.findOne({ where: { email } });
    if (!user) {
      return { error: 'Email Not Registered', status: 400 };
    }
    if (!user.isEmailVerified) {
      return { error: 'Email not verified', status: 400 };
    }
    return authService.authenticateAndGenerateToken(email, password, meta);
  },

  async verifyEmail(token) {
    return authService.verifyEmail(token);
  },

  async getCustomer(token) {
    const email = jwtService.extractEmail(token);
    if (!email) return null;
    return this.getCustomerByEmail(email);
  },

  /** The customer profile behind an already-authenticated email. */
  async getCustomerByEmail(email) {
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

  /**
   * Normalises page/limit and returns Sequelize's limit/offset pair.
   * Delegates to the shared helper so the order endpoints agree with these
   * on what a page is; kept as a method because callers here already use it.
   */
  _paging(options) {
    return normalisePaging(options);
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

  // ---------------------------------------------------------------------------
  // Addresses
  // ---------------------------------------------------------------------------

  /**
   * Delivery addresses are reusable rows, not free text typed at checkout.
   * The old checkout collected a string that went into Razorpay's notes and
   * nowhere else, so every real order had a null shipping_address_id and no
   * coordinates to deliver against.
   */
  async listAddresses(customerId) {
    const addresses = await Address.findAll({
      where: { customer_id: customerId },
      order: [['is_default', 'DESC'], ['id', 'DESC']],
    });
    return addresses.map(toAddressDto);
  },

  /** Required fields mirror the Address model's allowNull: false columns. */
  _validateAddress(data) {
    const missing = ['line1', 'city', 'state', 'postalCode', 'country'].filter(
      (field) => !String(data?.[field] ?? '').trim()
    );
    return missing.length ? `Missing required address fields: ${missing.join(', ')}` : null;
  },

  async createAddress(customerId, data) {
    const invalid = this._validateAddress(data);
    if (invalid) return { error: invalid, status: 400 };

    const existing = await Address.count({ where: { customer_id: customerId } });
    // The first address a customer saves becomes their default, so checkout
    // always has something preselected.
    const isDefault = existing === 0 ? true : Boolean(data.isDefault);

    const address = await sequelize.transaction(async (transaction) => {
      if (isDefault) {
        await Address.update(
          { isDefault: false },
          { where: { customer_id: customerId }, transaction }
        );
      }
      return Address.create(
        {
          customerId,
          label: data.label ?? null,
          line1: data.line1,
          line2: data.line2 ?? null,
          city: data.city,
          state: data.state,
          postalCode: data.postalCode,
          country: data.country,
          latitude: data.latitude ?? null,
          longitude: data.longitude ?? null,
          isDefault,
        },
        { transaction }
      );
    });

    return toAddressDto(address);
  },

  /** Loads an address only if it belongs to the calling customer. */
  async _ownedAddress(customerId, addressId) {
    const id = Number.parseInt(addressId, 10);
    if (Number.isNaN(id)) return { error: 'Invalid address id', status: 400 };

    const address = await Address.findByPk(id);
    if (!address) return { error: 'Address not found', status: 404 };
    if (String(address.customerId) !== String(customerId)) {
      return { error: 'Address does not belong to this customer', status: 403 };
    }
    return { address };
  },

  async updateAddress(customerId, addressId, data) {
    const owned = await this._ownedAddress(customerId, addressId);
    if (owned.error) return owned;

    const merged = { ...owned.address.get(), ...data };
    const invalid = this._validateAddress(merged);
    if (invalid) return { error: invalid, status: 400 };

    const fields = ['label', 'line1', 'line2', 'city', 'state', 'postalCode', 'country', 'latitude', 'longitude'];
    for (const field of fields) {
      if (data[field] !== undefined) owned.address[field] = data[field];
    }

    await sequelize.transaction(async (transaction) => {
      if (data.isDefault === true) {
        await Address.update(
          { isDefault: false },
          { where: { customer_id: customerId }, transaction }
        );
        owned.address.isDefault = true;
      }
      await owned.address.save({ transaction });
    });

    return toAddressDto(owned.address);
  },

  async setDefaultAddress(customerId, addressId) {
    const owned = await this._ownedAddress(customerId, addressId);
    if (owned.error) return owned;

    await sequelize.transaction(async (transaction) => {
      await Address.update(
        { isDefault: false },
        { where: { customer_id: customerId }, transaction }
      );
      owned.address.isDefault = true;
      await owned.address.save({ transaction });
    });

    return toAddressDto(owned.address);
  },

  /**
   * Addresses are referenced by past orders, so a delete must not cascade
   * into order history. OrderRecord.shippingAddressId is nullable and its
   * association has no CASCADE, so the order keeps pointing at nothing —
   * which is why an address still referenced by an order is kept and simply
   * unflagged as default instead.
   */
  async deleteAddress(customerId, addressId) {
    const owned = await this._ownedAddress(customerId, addressId);
    if (owned.error) return owned;

    const referencingOrders = await OrderRecord.count({
      where: { shipping_address_id: owned.address.id },
    });
    if (referencingOrders > 0) {
      return {
        error: 'This address is used by past orders and cannot be removed',
        status: 409,
      };
    }

    const wasDefault = owned.address.isDefault;
    await owned.address.destroy();

    // Promote another address so the customer is never left without a default.
    if (wasDefault) {
      const next = await Address.findOne({
        where: { customer_id: customerId },
        order: [['id', 'ASC']],
      });
      if (next) {
        next.isDefault = true;
        await next.save();
      }
    }

    return { message: 'Address removed' };
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

  /**
   * The cart's product lookup. Goes through the same include tree and DTO as
   * every other product endpoint: raw entities send `images` and `colors` as
   * association rows, and the client's model casts each element to a String,
   * so returning them unmapped threw on the first cart fetch.
   */
  async fetchProductsByIds(ids) {
    const products = await Product.findAll({
      where: { id: ids },
      include: this._productIncludes(),
    });
    return products.map(toProductDto);
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
  async getAffordableProductsByLocation({ city, state, pincode, latitude, longitude, radiusKm = 10, maxPriceInPaise, page, limit }) {
    const paging = this._paging({ page, limit });
    const locationWhere = this._buildLocationWhere({ city, state, pincode, latitude, longitude, radiusKm });

    const shops = await Shop.findAll({
      where: { isActive: true },
      attributes: ['id'],
      include: locationWhere
        ? [{ association: 'locationInfo', where: locationWhere, required: true, attributes: [] }]
        : [],
    });

    if (!shops.length) {
      return { total: 0, page: paging.page, limit: paging.limit, totalPages: 0, products: [] };
    }

    const productWhere = { shop_id: shops.map((s) => s.id), available: true };
    const cap = Number.parseInt(maxPriceInPaise, 10);
    if (Number.isFinite(cap) && cap > 0) {
      productWhere.price_in_paise = { [Op.lte]: cap };
    }

    const { count, rows } = await Product.findAndCountAll({
      where: productWhere,
      // The shared include tree, not a hand-rolled subset: this endpoint used
      // to load a narrower one and return the raw rows, so every product it
      // sent failed to parse client-side and the whole section read as empty.
      include: this._productIncludes(),
      order: [['price_in_paise', 'ASC']],
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
};

module.exports = customerService;

