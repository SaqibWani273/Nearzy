const { NearzyUser, Admin, ProductCategory, ShopVerification, Shop } = require('../models');
const authService = require('./authService');
const jwtService = require('./jwtService');

const adminService = {
  async registerAdmin(adminData, secretCode) {
    const adminPassword = process.env.ADMIN_PASSWORD || 'saqib@273';
    
    const result = await authService.preRegistrationProcess(adminData);
    if (typeof result === 'string') {
      return { error: result, status: 400 };
    }

    if (secretCode !== adminPassword) {
      return { error: 'Invalid Secret Code', status: 400 };
    }

    adminData.role = 'ADMIN';
    const user = await NearzyUser.create(adminData);
    await Admin.create({ userId: user.id });

    const emailResult = await authService.sendVerificationEmail(user, 'admin/verify-email?token=');
    return emailResult;
  },

  async login(email, password) {
    const user = await NearzyUser.findOne({ where: { email } });
    if (!user || !user.role || !user.role.includes('ADMIN')) {
      return { error: 'Invalid Admin credentials', status: 400 };
    }
    return authService.authenticateAndGenerateToken(email, password);
  },

  async verifyEmail(token) {
    return authService.verifyEmail(token);
  },

  async verifyToken(token) {
    const email = jwtService.extractEmail(token);
    if (!email) {
      return { error: 'Invalid Token', status: 400 };
    }
    const user = await NearzyUser.findOne({ where: { email } });
    if (!user) {
      return { error: 'No User Found', status: 400 };
    }
    if (user.role && user.role.includes('ADMIN')) {
      return { message: 'Email Verified' };
    }
    return { error: 'Invalid Token', status: 400 };
  },

  async addCategory(categoryData) {
    if (categoryData.id) {
      delete categoryData.id;
    }

    // Auto-generate slug if not provided
    if (!categoryData.slug && categoryData.name) {
      categoryData.slug = categoryData.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
    }

    console.log('adding category', categoryData);
    const category = await ProductCategory.create(categoryData);
    return { message: 'Category added successfully', category };
  },

  async verifyShop(shopId, adminUserId, status) {
    const admin = await Admin.findOne({ where: { user_id: adminUserId } });
    const verification = await ShopVerification.findOne({ where: { shop_id: shopId } });
    if (!verification) {
      return { error: 'Verification record not found', status: 404 };
    }

    verification.status = status; // 'APPROVED' or 'REJECTED'
    verification.verifiedByAdminId = admin ? admin.id : null;
    verification.verifiedAt = new Date();
    await verification.save();

    return { message: `Shop verification status updated to ${status}` };
  },
};

module.exports = adminService;
