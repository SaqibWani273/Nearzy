const { MyUser, ProductCategory } = require('../models');

const commonService = {
  async getAllCategories() {
    return ProductCategory.findAll();
  },

  async emailExists(email) {
    const user = await MyUser.findOne({ where: { email } });
    return !!user;
  },

  async usernameExists(username) {
    const user = await MyUser.findOne({ where: { username } });
    return !!user;
  },
};

module.exports = commonService;
