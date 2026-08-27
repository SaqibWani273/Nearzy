const { NearzyUser, Shop, ShopVerification, Product, ProductImage, ProductColor, LocationInfo, ProductCategory } = require('../models');
const authService = require('./authService');
const jwtService = require('./jwtService');

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
      user_id: user.id,
      name: shopData.name || 'Unnamed Shop',
      slug,
      shopPicUrl: shopData.shopPicUrl,
      phoneNumber: shopData.phoneNumber,
      address: shopData.address,
      description: shopData.description,
      isActive: shopData.isActive !== undefined ? shopData.isActive : true,
      location_id: locationId,
    });

    // Create initial ShopVerification record
    await ShopVerification.create({
      shop_id: shop.id,
      owner_name: shopData.ownerName || shopData.name || 'Shop Owner',
      owner_pic_url: shopData.ownerPicUrl || null,
      pancard_pic_url: shopData.pancardPicUrl || null,
      owner_id_pic_url: shopData.ownerIdPicUrl || null,
      business_license: shopData.businessLicense || null,
      status: 'PENDING',
      submitted_at: new Date(),
    });

    // Associate categories if provided
    if (Array.isArray(shopData.categoryIds) && shopData.categoryIds.length > 0) {
      const categories = await ProductCategory.findAll({ where: { id: shopData.categoryIds } });
      await shop.setCategories(categories);
    }

    const emailResult = await authService.sendVerificationEmail(user, 'shop/verify-email?token=');
    return emailResult;
  },

  async loginShop(email, password) {
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
            product_id: product.id,
            url,
            display_order: typeof img === 'object' && img.displayOrder !== undefined ? img.displayOrder : i,
            is_primary: typeof img === 'object' && img.isPrimary !== undefined ? img.isPrimary : i === 0,
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
            product_id: product.id,
            color_name: colorName,
            hex_code: hexCode,
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
