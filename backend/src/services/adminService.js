const { MyUser, Admin, ProductCategory } = require('../models');
const authService = require('./authService');
const jwtService = require('./jwtService');

const adminService = {
  async registerAdmin(adminData, secretCode) {
    const adminPassword = process.env.ADMIN_PASSWORD;
    
    const result = await authService.preRegistrationProcess(adminData);
    if (typeof result === 'string') {
      return { error: result, status: 400 };
    }

    if (secretCode !== adminPassword) {
      return { error: 'Invalid Secret Code', status: 400 };
    }

    adminData.roles = 'ADMIN';
    const user = await MyUser.create(adminData);
    await Admin.create({ user_id: user.id });

    const emailResult = await authService.sendVerificationEmail(user, 'admin/verify-email?token=');
    return emailResult;
  },

  async login(email, password) {
    const user = await MyUser.findOne({ where: { email } });
    if (!user || !user.roles || !user.roles.includes('ADMIN')) {
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
    const user = await MyUser.findOne({ where: { email } });
    if (!user) {
      return { error: 'No User Found', status: 400 };
    }
    if (user.roles && user.roles.includes('ADMIN')) {
      return { message: 'Email Verified' };
    }
    return { error: 'Invalid Token', status: 400 };
  },

  async addCategory(categoryData) {
    if (categoryData.id) {
      delete categoryData.id;
    }
    console.log('adding category', categoryData);
    await ProductCategory.create(categoryData);
    return { message: 'Category added successfully' };
  },
};

module.exports = adminService;
