const { NearzyUser, ProductCategory } = require('../models');

const commonService = {
  async getAllCategories() {
    return ProductCategory.findAll({
      order: [['display_order', 'ASC']],
      include: [
        { association: 'children' },
      ],
    });
  },

  async emailExists(email) {
    const user = await NearzyUser.findOne({ where: { email } });
    return !!user;
  },

  async usernameExists(username) {
    const user = await NearzyUser.findOne({ where: { username } });
    return !!user;
  },
};

module.exports = commonService;
