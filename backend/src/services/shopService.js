const { sequelize, NearzyUser, Shop, ShopVerification, Product, ProductImage, ProductColor, LocationInfo, ProductCategory, OrderItem } = require('../models');
const alertService = require('./alertService');
const authService = require('./authService');
const { toProductDto } = require('../dto/productDto');
const jwtService = require('./jwtService');
const { Op } = require('sequelize');

const shopService = {
  async registerShop(shopData) {
    const userData = shopData.user || shopData.myUser;
    if (!userData) {
      return { error: 'User data is required', status: 400 };
    }

    const result = await authService.preRegistrationProcess(userData);
    if (typeof result === 'string') {
      return { error: result, status: 400 };
    }

    userData.role = 'SHOP_OWNER';
    const user = await NearzyUser.create(userData);

    // Create LocationInfo if provided
    let locationId = null;
    if (shopData.locationInfo) {
      const location = await LocationInfo.create(shopData.locationInfo);
      locationId = location.id;
    }

    // Generate slug if not present
    const slug = shopData.slug || (shopData.name ? shopData.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') : `shop-${user.id}`);

    const shop = await Shop.create({
      userId: user.id,
      name: shopData.name || 'Unnamed Shop',
      slug,
      shopPicUrl: shopData.shopPicUrl,
      phoneNumber: shopData.phoneNumber,
      address: shopData.address,
      description: shopData.description,
      isActive: shopData.isActive !== undefined ? shopData.isActive : true,
      locationId,
    });

    // Create initial ShopVerification record
    await ShopVerification.create({
      shopId: shop.id,
      ownerName: shopData.ownerName || shopData.name || 'Shop Owner',
      ownerPicUrl: shopData.ownerPicUrl || null,
      pancardPicUrl: shopData.pancardPicUrl || null,
      ownerIdPicUrl: shopData.ownerIdPicUrl || null,
      businessLicense: shopData.businessLicense || null,
      status: 'PENDING',
      submittedAt: new Date(),
    });

    // Associate categories if provided
    if (Array.isArray(shopData.categoryIds) && shopData.categoryIds.length > 0) {
      const categories = await ProductCategory.findAll({ where: { id: shopData.categoryIds } });
      await shop.setCategories(categories);
    }

    const emailResult = await authService.sendVerificationEmail(user, 'shop/verify-email?token=');
    return emailResult;
  },

  async loginShop(email, password, meta = {}) {
    const user = await NearzyUser.findOne({ where: { email } });
    if (!user) {
      return { error: 'Email Not Registered', status: 400 };
    }
    if (!user.isEmailVerified) {
      return { error: 'Email not verified', status: 400 };
    }
    if (user.role !== 'SHOP_OWNER' && user.role !== 'SHOP') {
      return { error: 'Not a shop user', status: 400 };
    }
    return authService.authenticateAndGenerateToken(email, password, meta);
  },

  async verifyEmail(token) {
    return authService.verifyEmail(token);
  },

  async getShop(token) {
    const email = jwtService.extractEmail(token);
    if (!email) {
      return { error: 'Invalid token', status: 400 };
    }
    return this.getShopByEmail(email);
  },

  /** The shop profile behind an already-authenticated email. */
  async getShopByEmail(email) {
    const user = await NearzyUser.findOne({ where: { email } });
    if (!user) {
      return { error: 'User not found', status: 400 };
    }
    const shop = await Shop.findOne({
      where: { user_id: user.id },
      include: [
        { association: 'user' },
        { association: 'locationInfo' },
        { association: 'verification' },
        { association: 'categories' },
        {
          association: 'products',
          include: [
            { association: 'images' },
            { association: 'colors' },
            { association: 'category' },
          ],
        },
      ],
    });
    return shop;
  },

  /**
   * GET /shop/my-products
   *
   * The shop's own inventory, including items it has marked unavailable —
   * the owner needs to see and edit those, unlike a customer.
   *
   * `userId` comes from the caller's JWT, never the request body, so one shop
   * cannot enumerate another's stock.
   */
  async getMyProducts(userId, { page = 1, limit = 50, q } = {}) {
    const shop = await Shop.findOne({ where: { user_id: userId }, attributes: ['id'] });
    if (!shop) return { error: 'No shop profile for this account', status: 404 };

    const parsedLimit = Math.min(Math.max(Number.parseInt(limit, 10) || 50, 1), 200);
    const parsedPage = Math.max(Number.parseInt(page, 10) || 1, 1);

    const where = { shop_id: shop.id };
    const term = (q || '').trim();
    if (term.length >= 2) {
      where[Op.or] = [
        { name: { [Op.iLike]: `%${term}%` } },
        { sku: { [Op.iLike]: `%${term}%` } },
      ];
    }

    const { count, rows } = await Product.findAndCountAll({
      where,
      include: this._productIncludes(),
      order: [['id', 'DESC']],
      limit: parsedLimit,
      offset: (parsedPage - 1) * parsedLimit,
      distinct: true,
    });

    return {
      total: count,
      page: parsedPage,
      limit: parsedLimit,
      totalPages: Math.ceil(count / parsedLimit),
      products: rows.map((p) => this._toOwnerProductDto(p)),
    };
  },

  /**
   * PATCH /shop/products/:id
   *
   * Fields are whitelisted rather than spread from the body: `shopId`, `id`
   * and the rating aggregates must not be settable by the client, and a
   * blanket `product.update(req.body)` would make all of them so.
   *
   * Ownership is resolved from the caller's JWT, exactly as `getMyProducts`
   * does, so one shop cannot edit another's stock by guessing an id.
   */
  async updateProduct(userId, productId, patch = {}) {
    const shop = await Shop.findOne({ where: { user_id: userId }, attributes: ['id'] });
    if (!shop) return { error: 'No shop profile for this account', status: 404 };

    const id = Number.parseInt(productId, 10);
    if (Number.isNaN(id)) return { error: 'Invalid product id', status: 400 };

    const product = await Product.findByPk(id);
    if (!product) return { error: 'Product not found', status: 404 };
    // 404 rather than 403: a shop has no business learning which ids exist
    // outside its own inventory.
    if (String(product.shopId) !== String(shop.id)) {
      return { error: 'Product not found', status: 404 };
    }

    const numeric = {
      priceInPaise: (v) => Number.isInteger(v) && v > 0,
      discountPercent: (v) => typeof v === 'number' && v >= 0 && v <= 100,
      stockQuantity: (v) => Number.isInteger(v) && v >= 0,
      markdownFloorPercent: (v) => typeof v === 'number' && v >= 0 && v <= 100,
    };

    for (const [field, isValid] of Object.entries(numeric)) {
      if (patch[field] === undefined) continue;
      const value = Number(patch[field]);
      if (!isValid(value)) {
        return { error: `Invalid value for ${field}`, status: 400 };
      }
      product[field] = value;
    }

    for (const field of ['available', 'markdownEnabled']) {
      if (patch[field] === undefined) continue;
      product[field] = Boolean(patch[field]);
    }

    // An owner editing the discount by hand is restating their standing price,
    // not fighting the markdown engine — so that becomes the new baseline the
    // midnight reset returns to. Otherwise the next reset would revert the
    // edit they just made.
    if (patch.discountPercent !== undefined) {
      product.baseDiscountPercent = product.discountPercent;
    }

    // An explicit `available` in the same patch outranks the stockout hook:
    // the owner is speaking directly, so clear the stamp that would let a
    // later restock overrule them.
    if (patch.available !== undefined && patch.available === false) {
      product.autoUnpublishedAt = null;
    }

    await product.save();

    const saved = await Product.findByPk(product.id, { include: this._productIncludes() });
    return { message: 'Product updated', product: this._toOwnerProductDto(saved) };
  },

  /**
   * GET /shop/products/:id
   *
   * One product from the caller's own inventory, including items it has marked
   * unavailable. The edit sheet opens from places that hold only an id — a
   * low-stock alert, a scanned barcode — and needs the current values before
   * it can show them.
   */
  async getMyProduct(userId, productId) {
    const shop = await Shop.findOne({ where: { user_id: userId }, attributes: ['id'] });
    if (!shop) return { error: 'No shop profile for this account', status: 404 };

    const id = Number.parseInt(productId, 10);
    if (Number.isNaN(id)) return { error: 'Invalid product id', status: 400 };

    const product = await Product.findByPk(id, { include: this._productIncludes() });
    if (!product || String(product.shopId) !== String(shop.id)) {
      return { error: 'Product not found', status: 404 };
    }

    return { product: this._toOwnerProductDto(product) };
  },

  /**
   * POST /shop/products/bulk-stock
   *
   * Applies a batch of `{ sku, delta }` (or `{ sku, stockQuantity }`) moves in
   * one transaction. Built for the barcode scanner, where a shelf sweep
   * produces dozens of adjustments that should land together or not at all.
   *
   * Unknown SKUs are reported per row rather than failing the batch — a
   * scanner will inevitably pick up an item the shop has never listed, and
   * losing forty good scans to one stray barcode is the wrong trade.
   */
  async bulkAdjustStock(userId, entries) {
    const shop = await Shop.findOne({ where: { user_id: userId }, attributes: ['id'] });
    if (!shop) return { error: 'No shop profile for this account', status: 404 };

    if (!Array.isArray(entries) || entries.length === 0) {
      return { error: 'No stock entries supplied', status: 400 };
    }
    if (entries.length > 500) {
      return { error: 'Too many entries in one batch (max 500)', status: 400 };
    }

    const results = [];
    await sequelize.transaction(async (transaction) => {
      for (const entry of entries) {
        const sku = String(entry?.sku ?? '').trim();
        if (!sku) {
          results.push({ sku: entry?.sku ?? null, status: 'INVALID', reason: 'Missing sku' });
          continue;
        }

        const product = await Product.findOne({
          where: { sku, shop_id: shop.id },
          transaction,
          lock: transaction.LOCK.UPDATE,
        });
        if (!product) {
          results.push({ sku, status: 'UNMATCHED' });
          continue;
        }

        const hasAbsolute = entry.stockQuantity !== undefined;
        const next = hasAbsolute
          ? Number(entry.stockQuantity)
          : product.stockQuantity + Number(entry.delta ?? 0);

        if (!Number.isFinite(next) || !Number.isInteger(next)) {
          results.push({ sku, status: 'INVALID', reason: 'Non-integer quantity' });
          continue;
        }

        product.stockQuantity = Math.max(0, next);
        // Instance save, so the availability hook runs for every scanned row.
        await product.save({ transaction });

        results.push({
          sku,
          status: 'APPLIED',
          productId: product.id,
          name: product.name,
          stockQuantity: product.stockQuantity,
          available: product.available,
        });
      }
    });

    const applied = results.filter((r) => r.status === 'APPLIED').length;
    return {
      applied,
      unmatched: results.filter((r) => r.status === 'UNMATCHED').length,
      invalid: results.filter((r) => r.status === 'INVALID').length,
      results,
    };
  },

  /**
   * GET /shop/dashboard
   *
   * The triage payload. Everything here answers "what should I do next?" —
   * counts the owner can act on, not statistics. The shop home screen was
   * previously a bare tab shell that opened onto an inventory list, which told
   * an owner nothing about the two orders waiting on them.
   */
  async getDashboard(userId) {
    const shop = await Shop.findOne({
      where: { user_id: userId },
      attributes: ['id', 'name'],
      include: [{ association: 'verification', attributes: ['status'] }],
    });
    if (!shop) return { error: 'No shop profile for this account', status: 404 };

    const [pendingOrders, alertCounts, alerts, inventory] = await Promise.all([
      // Orders carrying this shop's items that it has not yet dispatched.
      // Counted over distinct orders, since one order may hold several of
      // this shop's lines and is still one thing to pack.
      OrderItem.count({
        distinct: true,
        col: 'order_id',
        where: { shop_id: shop.id },
        include: [
          {
            association: 'order',
            attributes: [],
            required: true,
            where: { status: { [Op.in]: ['PLACED', 'CONFIRMED'] } },
          },
        ],
      }),
      alertService.countsForShop(shop.id),
      alertService.listForShop(shop.id, { status: 'OPEN' }),
      Product.findAll({
        where: { shop_id: shop.id },
        attributes: [
          [sequelize.fn('COUNT', sequelize.col('id')), 'total'],
          [
            sequelize.fn(
              'COUNT',
              sequelize.literal("CASE WHEN available = false THEN 1 END")
            ),
            'unavailable',
          ],
          [
            sequelize.fn(
              'COUNT',
              sequelize.literal("CASE WHEN stock_quantity = 0 THEN 1 END")
            ),
            'outOfStock',
          ],
        ],
        raw: true,
      }),
    ]);

    const counts = inventory[0] || {};

    return {
      shop: { id: shop.id, name: shop.name ?? '' },
      verificationStatus: shop.verification?.status ?? 'PENDING',
      pendingOrders,
      alerts: {
        ...alertCounts,
        items: alerts,
      },
      inventory: {
        total: Number(counts.total ?? 0),
        unavailable: Number(counts.unavailable ?? 0),
        outOfStock: Number(counts.outOfStock ?? 0),
      },
    };
  },

  /** GET /shop/alerts */
  async listAlerts(userId, { status } = {}) {
    const shop = await Shop.findOne({ where: { user_id: userId }, attributes: ['id'] });
    if (!shop) return { error: 'No shop profile for this account', status: 404 };
    return { alerts: await alertService.listForShop(shop.id, { status }) };
  },

  /** PATCH /shop/alerts/:id */
  async setAlertStatus(userId, alertId, status) {
    const shop = await Shop.findOne({ where: { user_id: userId }, attributes: ['id'] });
    if (!shop) return { error: 'No shop profile for this account', status: 404 };
    return alertService.setStatus(shop.id, alertId, status);
  },

  /**
   * The customer product DTO plus the fields only the owner sees.
   *
   * These stay out of `toProductDto` on purpose: markdown settings and the
   * auto-unpublish stamp are operational state, and putting them on the public
   * product feed would ship every shop's pricing strategy to every customer.
   */
  _toOwnerProductDto(product) {
    return {
      ...toProductDto(product),
      markdownEnabled: Boolean(product.markdownEnabled),
      markdownFloorPercent: Number(product.markdownFloorPercent) || 0,
      baseDiscountPercent: Number(product.baseDiscountPercent) || 0,
      // Non-null means the stockout hook hid this, not the owner — which is
      // what lets the inventory list explain why an item is not showing.
      autoUnpublishedAt: product.autoUnpublishedAt ?? null,
    };
  },

  /** The include tree the product DTO expects. Shared by the write endpoints. */
  _productIncludes() {
    return [
      {
        association: 'shop',
        include: [
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

  async addProduct(productData) {
    console.log('adding product', productData);

    // Map legacy fields if passed
    if (productData.price !== undefined && productData.priceInPaise === undefined) {
      productData.priceInPaise = productData.price;
    }
    if (productData.discountInPercentage !== undefined && productData.discountPercent === undefined) {
      productData.discountPercent = productData.discountInPercentage;
    }

    const product = await Product.create(productData);

    // Handle product images if provided as array of URLs or objects
    if (Array.isArray(productData.images)) {
      for (let i = 0; i < productData.images.length; i++) {
        const img = productData.images[i];
        const url = typeof img === 'string' ? img : img.url;
        if (url) {
          await ProductImage.create({
            productId: product.id,
            url,
            displayOrder: typeof img === 'object' && img.displayOrder !== undefined ? img.displayOrder : i,
            isPrimary: typeof img === 'object' && img.isPrimary !== undefined ? img.isPrimary : i === 0,
          });
        }
      }
    }

    // Handle product colors if provided as array of color names or objects
    if (Array.isArray(productData.colors)) {
      for (const col of productData.colors) {
        const colorName = typeof col === 'string' ? col : col.colorName || col.color_name;
        const hexCode = typeof col === 'object' ? col.hexCode || col.hex_code : null;
        if (colorName) {
          await ProductColor.create({
            productId: product.id,
            colorName,
            hexCode,
          });
        }
      }
    }

    const createdProduct = await Product.findByPk(product.id, {
      include: [
        { association: 'images' },
        { association: 'colors' },
        { association: 'category' },
        { association: 'shop' },
      ],
    });

    return {
      message: `Product Added -> ${JSON.stringify(createdProduct)}`,
      product: createdProduct,
    };
  },
};

module.exports = shopService;
