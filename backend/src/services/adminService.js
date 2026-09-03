const { sequelize, NearzyUser, Admin, ProductCategory, ShopVerification, Shop, Product, Customer } = require('../models');
const authService = require('./authService');
const jwtService = require('./jwtService');
const { paging, envelope } = require('../utils/paging');
const { toVerificationDto } = require('../dto/verificationDto');

/** Mirrors the `status` validator on the ShopVerification model. */
const VERIFICATION_STATUSES = ['PENDING', 'APPROVED', 'REJECTED'];

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

  async login(email, password, meta = {}) {
    const user = await NearzyUser.findOne({ where: { email } });
    if (!user || !user.role || !user.role.includes('ADMIN')) {
      return { error: 'Invalid Admin credentials', status: 400 };
    }
    return authService.authenticateAndGenerateToken(email, password, meta);
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

  /**
   * GET /admin/shop-verifications
   *
   * The queue behind the admin's verification feed. `verifyShop` below has
   * existed since the shop model landed, but nothing could ever *read* the
   * pending applications, so submissions accumulated unseen.
   */
  async listShopVerifications({ page, limit, status = 'PENDING' } = {}) {
    const page_ = paging({ page, limit });

    const where = {};
    const wanted = String(status || '').trim().toUpperCase();
    // 'ALL' deliberately skips the filter; anything else must be a real state
    // rather than silently returning everything.
    if (wanted && wanted !== 'ALL') {
      if (!VERIFICATION_STATUSES.includes(wanted)) {
        return { error: `Unknown status '${status}'`, status: 400 };
      }
      where.status = wanted;
    }

    const { count, rows } = await ShopVerification.findAndCountAll({
      where,
      include: [
        {
          association: 'shop',
          include: [
            { association: 'user', attributes: { exclude: ['passwordHash'] } },
            { association: 'locationInfo' },
          ],
        },
      ],
      // Oldest first: a verification queue is worked front to back, and an
      // applicant who has waited longest should not be buried by new arrivals.
      order: [['submitted_at', 'ASC']],
      limit: page_.limit,
      offset: page_.offset,
      distinct: true,
    });

    return envelope('verifications', {
      count,
      rows: rows.map(toVerificationDto),
      limit: page_.limit,
      page: page_.page,
    });
  },

  /**
   * GET /admin/stats
   *
   * The four counters on the admin overview, which until now rendered a
   * literal em dash each.
   */
  async getStats() {
    const [shops, activeShops, products, categories, pendingVerifications, customers] =
      await Promise.all([
        Shop.count(),
        Shop.count({ where: { is_active: true } }),
        Product.count(),
        ProductCategory.count(),
        ShopVerification.count({ where: { status: 'PENDING' } }),
        Customer.count(),
      ]);

    return {
      shops,
      activeShops,
      products,
      categories,
      pendingVerifications,
      customers,
    };
  },

  /**
   * GET /admin/demand-heatmap
   *
   * Where orders are actually being delivered, binned into a grid so the admin
   * can see which neighbourhoods are underserved and where the Haversine
   * radiuses should be widened.
   *
   * Delivery addresses are the source rather than shop locations: a shop's pin
   * says where supply already is, while the addresses say where the demand
   * came from, which is the question being asked. Orders without coordinates
   * are skipped — an address typed by hand and never geocoded cannot be
   * plotted, and dropping it is honest where guessing a centroid would not be.
   *
   * Note this plots *orders only*. Search queries are not logged anywhere in
   * this codebase, so demand that never converted is invisible here; capturing
   * it would need a search-log table and is deliberately not faked.
   */
  async getDemandHeatmap({ days = 30, precision = 2 } = {}) {
    const windowDays = Math.min(Math.max(Number.parseInt(days, 10) || 30, 1), 365);
    // Grid resolution in decimal degrees: 2 -> ~1.1km cells, 3 -> ~110m.
    const digits = Math.min(Math.max(Number.parseInt(precision, 10) || 2, 1), 4);

    const rows = await sequelize.query(
      `
      SELECT
        ROUND(a.latitude::numeric,  :digits) AS lat,
        ROUND(a.longitude::numeric, :digits) AS lng,
        COUNT(DISTINCT o.id)                 AS orders,
        SUM(o.total_amount_paise)            AS revenue_paise
      FROM order_records o
      JOIN addresses a ON a.id = o.shipping_address_id
      WHERE o.placed_at >= NOW() - (:windowDays * INTERVAL '1 day')
        AND o.status <> 'CANCELLED'
        AND a.latitude  IS NOT NULL
        AND a.longitude IS NOT NULL
      GROUP BY 1, 2
      ORDER BY orders DESC
      LIMIT 500
      `,
      {
        replacements: { digits, windowDays },
        type: sequelize.constructor.QueryTypes.SELECT,
      }
    );

    const points = rows.map((r) => ({
      lat: Number(r.lat),
      lng: Number(r.lng),
      orders: Number(r.orders),
      revenuePaise: Number(r.revenue_paise ?? 0),
    }));

    // The client paints opacity as weight/maxWeight, so it needs the peak
    // without having to scan the list itself.
    const maxOrders = points.reduce((max, p) => Math.max(max, p.orders), 0);

    return {
      windowDays,
      precision: digits,
      maxOrders,
      totalOrders: points.reduce((sum, p) => sum + p.orders, 0),
      points,
    };
  },

  async verifyShop(shopId, adminUserId, status) {
    const admin = await Admin.findOne({ where: { user_id: adminUserId } });
    const verification = await ShopVerification.findOne({ where: { shop_id: shopId } });
    if (!verification) {
      return { error: 'Verification record not found', status: 404 };
    }

    const decision = String(status || '').trim().toUpperCase();
    if (decision !== 'APPROVED' && decision !== 'REJECTED') {
      return { error: `Unknown status '${status}'`, status: 400 };
    }
    // A second decision on an already-judged application is almost always a
    // double-tap or a replayed request, not an intentional reversal.
    if (verification.status !== 'PENDING') {
      return { error: `Already ${verification.status.toLowerCase()}`, status: 409 };
    }

    verification.status = decision;
    verification.verifiedByAdminId = admin ? admin.id : null;
    verification.verifiedAt = new Date();
    await verification.save();

    return { message: `Shop verification status updated to ${decision}`, verification: toVerificationDto(verification) };
  },
};

module.exports = adminService;
