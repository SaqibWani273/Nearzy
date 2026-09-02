const { NearzyUser, Shop, ShopVerification, Product, ProductImage, ProductColor, LocationInfo, ProductCategory } = require('../models');
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
      include: [
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
      ],
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
      products: rows.map(toProductDto),
    };
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
