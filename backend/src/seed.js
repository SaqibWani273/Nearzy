/**
 * seed.js – Populate the Nearzy DB with realistic demo data.
 *
 * Usage:  node src/seed.js
 *
 * This is ADDITIVE – it checks for empty tables before inserting.
 * All demo user passwords: "Test@1234"
 */

require('dotenv').config();
const bcrypt = require('bcryptjs');
const {
  sequelize,
  NearzyUser,
  Admin,
  Customer,
  Address,
  Cart,
  LocationInfo,
  Shop,
  ShopVerification,
  ProductCategory,
  Product,
  ProductImage,
  ProductColor,
  Review,
  OrderRecord,
  OrderItem,
} = require('./models');

// ─── helpers ──────────────────────────────────────────────────────────────────
const hash = (pw) => bcrypt.hashSync(pw, 10);
const DEFAULT_PW = hash('Test@1234');
const rnd = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const pick = (arr) => arr[rnd(0, arr.length - 1)];
const pImg = (id, w = 400, h = 400) =>
  `https://picsum.photos/id/${id}/${w}/${h}`;

async function seed() {
  try {
    await sequelize.authenticate();
    console.log('✅ DB connected');

    // Check if data already exists. The guard is all-or-nothing on users, so a
    // single real signup blocks the whole seed; SEED_FORCE=1 runs it anyway.
    // Safe because every seeded account uses an @nearzy.com address of its own,
    // but it will collide if the demo data is seeded twice.
    const existingUsers = await NearzyUser.count();
    if (existingUsers > 0 && process.env.SEED_FORCE !== '1') {
      console.log('⚠️  Database already has data. Skipping seed.');
      console.log('   Re-run with SEED_FORCE=1 to seed alongside existing users.');
      process.exit(0);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1. ADMIN USER
    // ═══════════════════════════════════════════════════════════════════════════
    const adminUser = await NearzyUser.create({
      username: 'nearzy_admin',
      email: process.env.ADMIN_EMAIL || 'admin@nearzy.com',
      passwordHash: hash(process.env.ADMIN_PASSWORD || 'Admin@1234'),
      role: 'ADMIN',
      isEmailVerified: true,
    });
    const admin = await Admin.create({ userId: adminUser.id });
    console.log('👑 Admin created');

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. LOCATIONS (realistic Indian cities)
    // ═══════════════════════════════════════════════════════════════════════════
    const locations = await LocationInfo.bulkCreate([
      { shortAddress: 'Lal Chowk, Srinagar',     latitude: 34.0750, longitude: 74.7870, completeAddress: 'Lal Chowk Main Market, Srinagar, J&K 190001',        city: 'Srinagar', state: 'Jammu and Kashmir', pincode: '190001' },
      { shortAddress: 'Residency Road, Srinagar', latitude: 34.0837, longitude: 74.7973, completeAddress: 'Residency Road, Near TRC, Srinagar, J&K 190001',     city: 'Srinagar', state: 'Jammu and Kashmir', pincode: '190001' },
      { shortAddress: 'Polo View, Srinagar',      latitude: 34.0826, longitude: 74.7892, completeAddress: 'Polo View Market, Srinagar, J&K 190001',             city: 'Srinagar', state: 'Jammu and Kashmir', pincode: '190001' },
      { shortAddress: 'Raghunath Bazaar, Jammu',   latitude: 32.7338, longitude: 74.8691, completeAddress: 'Raghunath Bazaar, Jammu, J&K 180001',                city: 'Jammu',    state: 'Jammu and Kashmir', pincode: '180001' },
      { shortAddress: 'Connaught Place, Delhi',    latitude: 28.6315, longitude: 77.2167, completeAddress: 'Block A, Connaught Place, New Delhi 110001',          city: 'New Delhi', state: 'Delhi',             pincode: '110001' },
      { shortAddress: 'Chandni Chowk, Delhi',      latitude: 28.6507, longitude: 77.2334, completeAddress: 'Chandni Chowk Main Bazaar, Old Delhi 110006',        city: 'New Delhi', state: 'Delhi',             pincode: '110006' },
      { shortAddress: 'Colaba, Mumbai',            latitude: 18.9067, longitude: 72.8147, completeAddress: 'Colaba Causeway, Mumbai, Maharashtra 400005',         city: 'Mumbai',   state: 'Maharashtra',       pincode: '400005' },
      { shortAddress: 'MG Road, Bangalore',        latitude: 12.9757, longitude: 77.6062, completeAddress: 'MG Road, Bangalore, Karnataka 560001',               city: 'Bangalore', state: 'Karnataka',        pincode: '560001' },
    ]);
    console.log('📍 8 locations created');

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. SHOP OWNER USERS + SHOPS
    // ═══════════════════════════════════════════════════════════════════════════
    const shopsData = [
      { username: 'kashmir_shawls',      email: 'kashmir.shawls@nearzy.com',      name: 'Kashmir Shawl House',       slug: 'kashmir-shawl-house',        phone: '9191000001', address: 'Shop 12, Lal Chowk, Srinagar',        desc: 'Premium Pashmina and Shahtoosh shawls handwoven by master artisans of Kashmir Valley. Five generations of weaving excellence.',   locIdx: 0, picId: 1011 },
      { username: 'saffron_garden',      email: 'saffron.garden@nearzy.com',      name: 'Saffron Garden Kashmir',    slug: 'saffron-garden-kashmir',     phone: '9191000002', address: 'Residency Road, Srinagar',             desc: 'Authentic Kashmiri saffron (Kesar), dry fruits, and organic spices sourced directly from Pampore farms.',                         locIdx: 1, picId: 1080 },
      { username: 'woodcraft_kashmir',   email: 'woodcraft@nearzy.com',           name: 'Kashmir Woodcraft Emporium', slug: 'kashmir-woodcraft-emporium', phone: '9191000003', address: 'Polo View Market, Srinagar',            desc: 'Exquisite hand-carved walnut wood furniture, jewelry boxes, and decorative items. Traditional Khatamband ceiling work.',           locIdx: 2, picId: 1015 },
      { username: 'pashmina_palace',     email: 'pashmina.palace@nearzy.com',     name: 'Pashmina Palace',           slug: 'pashmina-palace',            phone: '9191000004', address: 'Raghunath Bazaar, Jammu',               desc: 'Curated collection of GI-tagged Pashmina shawls, stoles, and scarves. Each piece comes with a certificate of authenticity.',      locIdx: 3, picId: 1019 },
      { username: 'delhi_spice_market',  email: 'delhi.spices@nearzy.com',        name: 'Delhi Spice Market',        slug: 'delhi-spice-market',         phone: '9191000005', address: 'A-22, Connaught Place, New Delhi',      desc: 'India\'s finest whole and ground spices. Cumin, turmeric, cardamom, and exclusive spice blends from across the subcontinent.',    locIdx: 4, picId: 1060 },
      { username: 'heritage_silk',       email: 'heritage.silk@nearzy.com',       name: 'Heritage Silk & Textiles',  slug: 'heritage-silk-textiles',     phone: '9191000006', address: 'Chandni Chowk, Old Delhi',              desc: 'Banarasi silk sarees, lehengas, and bridal wear. Traditional handloom craftsmanship meeting contemporary designs.',               locIdx: 5, picId: 1005 },
      { username: 'mumbai_crafts',       email: 'mumbai.crafts@nearzy.com',       name: 'Mumbai Artisan Collective', slug: 'mumbai-artisan-collective', phone: '9191000007', address: 'Colaba Causeway, Mumbai',               desc: 'A curated marketplace bringing together local artisans. Handmade pottery, paintings, organic skincare, and home décor.',          locIdx: 6, picId: 1029 },
      { username: 'blr_organic_store',   email: 'blr.organic@nearzy.com',         name: 'Bangalore Organic Store',   slug: 'bangalore-organic-store',    phone: '9191000008', address: 'MG Road, Bangalore',                    desc: 'Farm-to-table organic groceries, cold-pressed oils, honey, herbal teas, and eco-friendly household products.',                    locIdx: 7, picId: 1047 },
    ];

    const shopRecords = [];
    for (const s of shopsData) {
      const user = await NearzyUser.create({
        username: s.username,
        email: s.email,
        passwordHash: DEFAULT_PW,
        role: 'SHOP',
        isEmailVerified: true,
      });
      const shop = await Shop.create({
        userId: user.id,
        locationId: locations[s.locIdx].id,
        name: s.name,
        slug: s.slug,
        shopPicUrl: pImg(s.picId, 600, 400),
        phoneNumber: s.phone,
        address: s.address,
        description: s.desc,
        isActive: true,
      });
      await ShopVerification.create({
        shopId: shop.id,
        ownerName: s.username.replace(/_/g, ' '),
        status: 'APPROVED',
        verifiedByAdminId: admin.id,
        verifiedAt: new Date(),
      });
      shopRecords.push(shop);
    }
    console.log('🏪 8 shops created & verified');

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. CUSTOMER USERS
    // ═══════════════════════════════════════════════════════════════════════════
    const customersData = [
      { username: 'aarav_sharma',    email: 'aarav@nearzy.com',    first: 'Aarav',    last: 'Sharma',    phone: '9876543201' },
      { username: 'priya_mehta',     email: 'priya@nearzy.com',    first: 'Priya',    last: 'Mehta',     phone: '9876543202' },
      { username: 'rohan_kumar',     email: 'rohan@nearzy.com',    first: 'Rohan',    last: 'Kumar',     phone: '9876543203' },
      { username: 'ananya_singh',    email: 'ananya@nearzy.com',   first: 'Ananya',   last: 'Singh',     phone: '9876543204' },
      { username: 'kabir_patel',     email: 'kabir@nearzy.com',    first: 'Kabir',    last: 'Patel',     phone: '9876543205' },
      { username: 'isha_reddy',      email: 'isha@nearzy.com',     first: 'Isha',     last: 'Reddy',     phone: '9876543206' },
      { username: 'dev_gupta',       email: 'dev@nearzy.com',      first: 'Dev',      last: 'Gupta',     phone: '9876543207' },
      { username: 'meera_nair',      email: 'meera@nearzy.com',    first: 'Meera',    last: 'Nair',      phone: '9876543208' },
      { username: 'arjun_kapoor',    email: 'arjun@nearzy.com',    first: 'Arjun',    last: 'Kapoor',    phone: '9876543209' },
      { username: 'zara_khan',       email: 'zara@nearzy.com',     first: 'Zara',     last: 'Khan',      phone: '9876543210' },
      { username: 'vihaan_das',      email: 'vihaan@nearzy.com',   first: 'Vihaan',   last: 'Das',       phone: '9876543211' },
      { username: 'tanya_bose',      email: 'tanya@nearzy.com',    first: 'Tanya',    last: 'Bose',      phone: '9876543212' },
      { username: 'saqib_wani',      email: 'saqib@nearzy.com',    first: 'Saqib',    last: 'Wani',      phone: '9876543213' },
      { username: 'neha_joshi',      email: 'neha@nearzy.com',     first: 'Neha',     last: 'Joshi',     phone: '9876543214' },
      { username: 'rahul_verma',     email: 'rahul@nearzy.com',    first: 'Rahul',    last: 'Verma',     phone: '9876543215' },
    ];

    const customerRecords = [];
    for (const c of customersData) {
      const user = await NearzyUser.create({
        username: c.username,
        email: c.email,
        passwordHash: DEFAULT_PW,
        role: 'CUSTOMER',
        isEmailVerified: true,
      });
      const customer = await Customer.create({
        userId: user.id,
        firstName: c.first,
        lastName: c.last,
        phoneNumber: c.phone,
      });
      await Cart.create({ customerId: customer.id });
      customerRecords.push(customer);
    }
    console.log('👤 15 customers created');

    // ═══════════════════════════════════════════════════════════════════════════
    // 5. ADDRESSES (for first 6 customers)
    // ═══════════════════════════════════════════════════════════════════════════
    const addressesData = [
      { custIdx: 0,  label: 'Home',   line1: '45 Gole Market',          line2: 'Near Hanuman Mandir',         city: 'New Delhi',  state: 'Delhi',              postal: '110001', country: 'India', lat: 28.6354, lng: 77.2090 },
      { custIdx: 0,  label: 'Office', line1: '12th Floor, Tower B',     line2: 'Cyber City, Sector 24',       city: 'Gurugram',   state: 'Haryana',            postal: '122002', country: 'India', lat: 28.4946, lng: 77.0886 },
      { custIdx: 1,  label: 'Home',   line1: 'A-14, Residency Road',   line2: null,                          city: 'Srinagar',   state: 'Jammu and Kashmir',  postal: '190001', country: 'India', lat: 34.0837, lng: 74.7973 },
      { custIdx: 2,  label: 'Home',   line1: '78 MG Road',             line2: 'Opposite Metro Station',      city: 'Bangalore',  state: 'Karnataka',          postal: '560001', country: 'India', lat: 12.9757, lng: 77.6062 },
      { custIdx: 3,  label: 'Home',   line1: '23 Marine Drive',        line2: null,                          city: 'Mumbai',     state: 'Maharashtra',        postal: '400002', country: 'India', lat: 18.9439, lng: 72.8236 },
      { custIdx: 4,  label: 'Home',   line1: '56 Lal Chowk',           line2: 'Above State Bank',            city: 'Srinagar',   state: 'Jammu and Kashmir',  postal: '190001', country: 'India', lat: 34.0750, lng: 74.7870 },
      { custIdx: 5,  label: 'Home',   line1: '9 Park Street',          line2: 'Flat 4A',                     city: 'Kolkata',    state: 'West Bengal',        postal: '700016', country: 'India', lat: 22.5521, lng: 88.3516 },
    ];

    for (const a of addressesData) {
      await Address.create({
        customerId: customerRecords[a.custIdx].id,
        label: a.label,
        line1: a.line1,
        line2: a.line2,
        city: a.city,
        state: a.state,
        postalCode: a.postal,
        country: a.country,
        latitude: a.lat,
        longitude: a.lng,
        isDefault: a.label === 'Home',
      });
    }
    console.log('📬 7 addresses created');

    // ═══════════════════════════════════════════════════════════════════════════
    // 6. PRODUCT CATEGORIES (hierarchical)
    // ═══════════════════════════════════════════════════════════════════════════
    // Top-level
    const catShawls    = await ProductCategory.create({ name: 'Shawls & Wraps',       slug: 'shawls-wraps',       imageUrl: pImg(403, 300, 300), description: 'Pashmina shawls, stoles, and wraps',            isTopCategory: true,  displayOrder: 1 });
    const catSpices    = await ProductCategory.create({ name: 'Spices & Saffron',      slug: 'spices-saffron',     imageUrl: pImg(292, 300, 300), description: 'Authentic spices, saffron, and seasoning blends', isTopCategory: true,  displayOrder: 2 });
    const catDryFruits = await ProductCategory.create({ name: 'Dry Fruits & Nuts',     slug: 'dry-fruits-nuts',    imageUrl: pImg(102, 300, 300), description: 'Premium almonds, walnuts, cashews, and more',    isTopCategory: true,  displayOrder: 3 });
    const catWoodcraft = await ProductCategory.create({ name: 'Woodcraft & Furniture', slug: 'woodcraft-furniture', imageUrl: pImg(164, 300, 300), description: 'Hand-carved walnut wood art and furniture',      isTopCategory: true,  displayOrder: 4 });
    const catTextiles  = await ProductCategory.create({ name: 'Silk & Textiles',       slug: 'silk-textiles',      imageUrl: pImg(335, 300, 300), description: 'Silk sarees, lehengas, and handloom fabrics',     isTopCategory: true,  displayOrder: 5 });
    const catTea       = await ProductCategory.create({ name: 'Tea & Beverages',       slug: 'tea-beverages',      imageUrl: pImg(225, 300, 300), description: 'Kehwa, green tea, herbal infusions',             isTopCategory: true,  displayOrder: 6 });
    const catCarpets   = await ProductCategory.create({ name: 'Carpets & Rugs',        slug: 'carpets-rugs',       imageUrl: pImg(139, 300, 300), description: 'Hand-knotted silk and woolen carpets',           isTopCategory: true,  displayOrder: 7 });
    const catJewelry   = await ProductCategory.create({ name: 'Jewelry & Accessories', slug: 'jewelry-accessories', imageUrl: pImg(238, 300, 300), description: 'Traditional and contemporary jewelry',           isTopCategory: true,  displayOrder: 8 });

    // Sub-categories
    const catPashmina  = await ProductCategory.create({ parentId: catShawls.id,    name: 'Pashmina Shawls',     slug: 'pashmina-shawls',      imageUrl: pImg(403, 300, 300), description: 'Pure pashmina shawls',        displayOrder: 1 });
    const catSilkShawl = await ProductCategory.create({ parentId: catShawls.id,    name: 'Silk Shawls',         slug: 'silk-shawls',          imageUrl: pImg(399, 300, 300), description: 'Silk blend shawls & stoles',  displayOrder: 2 });
    const catKesar     = await ProductCategory.create({ parentId: catSpices.id,    name: 'Kashmiri Saffron',    slug: 'kashmiri-saffron',     imageUrl: pImg(292, 300, 300), description: 'Premium Pampore saffron',     displayOrder: 1 });
    const catWhole     = await ProductCategory.create({ parentId: catSpices.id,    name: 'Whole Spices',        slug: 'whole-spices',         imageUrl: pImg(488, 300, 300), description: 'Whole and ground spices',     displayOrder: 2 });

    // Link shops to categories
    const shopCatMap = [
      [0, [catShawls.id, catPashmina.id, catSilkShawl.id]],
      [1, [catSpices.id, catKesar.id, catDryFruits.id, catTea.id]],
      [2, [catWoodcraft.id, catCarpets.id]],
      [3, [catShawls.id, catPashmina.id]],
      [4, [catSpices.id, catWhole.id, catDryFruits.id]],
      [5, [catTextiles.id, catShawls.id, catSilkShawl.id]],
      [6, [catJewelry.id, catWoodcraft.id]],
      [7, [catTea.id, catDryFruits.id, catSpices.id]],
    ];
    for (const [shopIdx, catIds] of shopCatMap) {
      await shopRecords[shopIdx].setCategories(catIds);
    }
    console.log('🏷️  12 categories created (8 top + 4 sub)');

    // ═══════════════════════════════════════════════════════════════════════════
    // 7. PRODUCTS (60+ realistic products)
    // ═══════════════════════════════════════════════════════════════════════════
    const productsData = [
      // ── Shop 0: Kashmir Shawl House ─────────────────────────────────────────
      { shopIdx: 0, catId: catPashmina.id,  name: 'Pure Pashmina Shawl – Sozni Embroidery',        brand: 'Kashmir Shawl House',   sku: 'KSH-001', shortDesc: 'Hand-embroidered Sozni pashmina in classic Chinar pattern',     fullDesc: 'This exquisite pashmina shawl features intricate Sozni embroidery done over 6 months by master artisans. The fabric is 100% pure pashmina (Grade A) sourced from Changthang goats at 14,000 ft altitude. Each thread tells a story of Kashmiri heritage.',  price: 1499900, discount: 15, stock: 8,  rating: 4.8, reviews: 24, imgIds: [403, 401, 405], colors: [['Ivory White','#FFFFF0'],['Deep Maroon','#800020'],['Royal Blue','#002366']] },
      { shopIdx: 0, catId: catPashmina.id,  name: 'Kani Pashmina Shawl – Jamawar Pattern',         brand: 'Kashmir Shawl House',   sku: 'KSH-002', shortDesc: 'Handwoven Kani shawl with traditional Jamawar design',          fullDesc: 'A masterpiece of Kani weaving, this shawl takes 18 months to complete. Woven on traditional wooden looms using coloured bobbins (kanis). Features the iconic Jamawar paisley pattern in rich jewel tones.',                                                   price: 3500000, discount: 10, stock: 3,  rating: 4.9, reviews: 12, imgIds: [399, 397, 400], colors: [['Natural Beige','#F5F0E1'],['Forest Green','#228B22']] },
      { shopIdx: 0, catId: catSilkShawl.id, name: 'Silk-Pashmina Blend Stole',                     brand: 'Kashmir Shawl House',   sku: 'KSH-003', shortDesc: 'Lightweight 70/30 silk-pashmina stole for all seasons',         fullDesc: '70% Pashmina, 30% Silk blend stole. Lightweight and versatile, perfect for both summer evenings and winter layering. Machine washable. Size: 200cm x 70cm.',                                                                                                  price: 399900,  discount: 20, stock: 25, rating: 4.5, reviews: 45, imgIds: [398, 396],      colors: [['Dusty Rose','#DCAE96'],['Slate Grey','#708090'],['Midnight Blue','#191970']] },
      { shopIdx: 0, catId: catPashmina.id,  name: 'Tilla Embroidery Pashmina Shawl',               brand: 'Kashmir Shawl House',   sku: 'KSH-004', shortDesc: 'Gold zari Tilla work on pure pashmina',                       fullDesc: 'A regal pashmina adorned with genuine gold and silver Tilla (metallic thread) embroidery. This art form dates back to the Mughal era. Perfect for weddings and special occasions.',                                                                            price: 2899900, discount: 0,  stock: 5,  rating: 5.0, reviews: 8,  imgIds: [404, 402],      colors: [['Gold on Black','#FFD700'],['Silver on Cream','#C0C0C0']] },

      // ── Shop 1: Saffron Garden Kashmir ──────────────────────────────────────
      { shopIdx: 1, catId: catKesar.id,     name: 'Premium Kashmiri Saffron (Mogra Grade)',         brand: 'Saffron Garden',        sku: 'SG-001',  shortDesc: '1g premium Mogra grade saffron from Pampore',                 fullDesc: 'ISO 3632 Category I saffron with coloring strength >250. Hand-harvested from our own farms in Pampore, Kashmir. Each gram contains approximately 450 stigmas, hand-picked at dawn.',                                                                         price: 79900,   discount: 5,  stock: 100, rating: 4.7, reviews: 89, imgIds: [292, 290],      colors: [] },
      { shopIdx: 1, catId: catKesar.id,     name: 'Saffron Gift Box – 5g Premium Pack',            brand: 'Saffron Garden',        sku: 'SG-002',  shortDesc: 'Luxury gift box with 5g Mogra saffron',                       fullDesc: 'Elegantly packaged 5g premium Kashmiri saffron in a handcrafted walnut wood box. Includes a certificate of authenticity and brewing guide. Perfect for gifting.',                                                                                             price: 349900,  discount: 10, stock: 30,  rating: 4.9, reviews: 32, imgIds: [163, 165],      colors: [] },
      { shopIdx: 1, catId: catDryFruits.id, name: 'Kashmiri Mamra Almonds – 500g',                 brand: 'Saffron Garden',        sku: 'SG-003',  shortDesc: 'Organic Mamra almonds, oil-rich & crunchy',                   fullDesc: 'Premium Mamra almonds from Kashmir valley. These rare almonds are smaller but packed with 50% more oil content than regular almonds. Air-dried, no preservatives.',                                                                                           price: 149900,  discount: 0,  stock: 50,  rating: 4.6, reviews: 67, imgIds: [102, 106],      colors: [] },
      { shopIdx: 1, catId: catDryFruits.id, name: 'Kashmir Walnut Kernels – 1kg',                  brand: 'Saffron Garden',        sku: 'SG-004',  shortDesc: 'Snow-white walnut halves from Kashmir',                       fullDesc: 'Hand-cracked Kashmiri walnut kernels. Light-coloured halves with a sweet, mild flavour. Rich in Omega-3 fatty acids. Vacuum-sealed for freshness.',                                                                                                          price: 119900,  discount: 12, stock: 40,  rating: 4.5, reviews: 55, imgIds: [139, 143],      colors: [] },
      { shopIdx: 1, catId: catTea.id,       name: 'Kashmiri Kehwa – Premium Blend (100g)',          brand: 'Saffron Garden',        sku: 'SG-005',  shortDesc: 'Traditional Kehwa with saffron, cardamom & almonds',          fullDesc: 'An authentic Kashmiri green tea blend infused with saffron strands, crushed cardamom, cinnamon, and almond flakes. Just add hot water and honey for the perfect cup.',                                                                                        price: 39900,   discount: 0,  stock: 80,  rating: 4.8, reviews: 110, imgIds: [225, 221],     colors: [] },

      // ── Shop 2: Kashmir Woodcraft Emporium ─────────────────────────────────
      { shopIdx: 2, catId: catWoodcraft.id, name: 'Hand-carved Walnut Wood Jewelry Box',            brand: 'Woodcraft Kashmir',     sku: 'WK-001',  shortDesc: 'Intricate Chinar leaf carving on premium walnut',             fullDesc: 'A stunning jewelry box carved from a single block of Kashmiri walnut wood. Features the iconic Chinar leaf pattern with a velvet-lined interior. Approx size: 8x6x4 inches.',                                                                                price: 249900,  discount: 10, stock: 15,  rating: 4.7, reviews: 28, imgIds: [164, 167],      colors: [['Natural Walnut','#5C4033']] },
      { shopIdx: 2, catId: catWoodcraft.id, name: 'Walnut Wood Table Lamp – Arabesque',             brand: 'Woodcraft Kashmir',     sku: 'WK-002',  shortDesc: 'Carved arabesque pattern table lamp with warm glow',          fullDesc: 'Handmade table lamp featuring arabesque geometric patterns. The warm light filtering through the carved wood creates mesmerizing shadow patterns. Height: 14 inches. Includes LED bulb.',                                                                     price: 449900,  discount: 15, stock: 10,  rating: 4.6, reviews: 19, imgIds: [169, 170],      colors: [['Dark Walnut','#3B2314'],['Honey Oak','#C7956D']] },
      { shopIdx: 2, catId: catWoodcraft.id, name: 'Papier-Mâché Decorative Vase',                   brand: 'Woodcraft Kashmir',     sku: 'WK-003',  shortDesc: 'Hand-painted papier-mâché vase with floral motifs',           fullDesc: 'Traditional Kashmiri papier-mâché vase with intricate hand-painted floral designs. Layered paper pulp, polished to a lacquer finish. Height: 12 inches.',                                                                                                    price: 189900,  discount: 0,  stock: 20,  rating: 4.4, reviews: 14, imgIds: [174, 175],      colors: [['Blue & Gold','#0000CD'],['Red & Gold','#B22222']] },
      { shopIdx: 2, catId: catCarpets.id,   name: 'Handknotted Silk Carpet – 4x6 ft',               brand: 'Woodcraft Kashmir',     sku: 'WK-004',  shortDesc: '576 KPSI pure silk carpet with medallion design',             fullDesc: 'An heirloom-quality hand-knotted silk carpet featuring a central medallion design. 576 knots per square inch (KPSI). Each carpet takes 2-3 years to weave. Comes with authenticity certificate.',                                                             price: 12999900, discount: 5, stock: 2,  rating: 5.0, reviews: 6,  imgIds: [171, 172],      colors: [['Ivory & Burgundy','#800020'],['Cream & Blue','#000080']] },

      // ── Shop 3: Pashmina Palace ─────────────────────────────────────────────
      { shopIdx: 3, catId: catPashmina.id,  name: 'Solid Color Pure Pashmina Wrap',                 brand: 'Pashmina Palace',       sku: 'PP-001',  shortDesc: 'Minimalist pure pashmina in solid vibrant colours',           fullDesc: 'Clean, solid-colour pashmina wraps. 100% GI-tagged pashmina. Size: 200x100cm. Perfect for everyday luxury. Comes with GI tag certificate.',                                                                                                                  price: 699900,  discount: 25, stock: 30,  rating: 4.6, reviews: 72, imgIds: [403, 407],      colors: [['Scarlet','#FF2400'],['Ocean Teal','#008080'],['Charcoal','#36454F'],['Blush Pink','#FFB6C1']] },
      { shopIdx: 3, catId: catPashmina.id,  name: 'Pashmina Embroidered Stole – Papier Mâché Style', brand: 'Pashmina Palace',      sku: 'PP-002',  shortDesc: 'Vibrant papier-mâché inspired embroidery on pashmina',       fullDesc: 'This stole combines the softness of pashmina with bold, colourful embroidery inspired by Kashmiri papier-mâché art. Handmade, no two pieces are identical.',                                                                                                  price: 999900,  discount: 0,  stock: 12,  rating: 4.8, reviews: 18, imgIds: [399, 401],      colors: [['Multi on Black','#000000'],['Multi on Ivory','#FFFFF0']] },
      { shopIdx: 3, catId: catSilkShawl.id, name: 'Men\'s Pashmina Muffler',                       brand: 'Pashmina Palace',       sku: 'PP-003',  shortDesc: 'Premium men\'s pashmina neck muffler',                        fullDesc: 'Designed for the modern gentleman. Pure pashmina muffler in understated tones. Size: 180x30cm. Perfect for suits and overcoats.',                                                                                                                            price: 299900,  discount: 10, stock: 35,  rating: 4.3, reviews: 29, imgIds: [398, 400],      colors: [['Graphite','#383838'],['Navy','#000080'],['Camel','#C19A6B']] },

      // ── Shop 4: Delhi Spice Market ──────────────────────────────────────────
      { shopIdx: 4, catId: catWhole.id,     name: 'Whole Spice Box – 12 Essential Spices',           brand: 'Delhi Spice Market',   sku: 'DSM-001', shortDesc: 'Curated box of 12 whole spices in a wooden masala dabba',     fullDesc: 'A beautiful wooden masala dabba containing 12 essential whole spices: cumin, mustard, fennel, fenugreek, coriander, cardamom, cloves, cinnamon, star anise, bay leaves, black pepper, and dried red chillies.',                                               price: 89900,   discount: 15, stock: 60,  rating: 4.7, reviews: 156, imgIds: [488, 452],     colors: [] },
      { shopIdx: 4, catId: catWhole.id,     name: 'Garam Masala – Stone Ground (250g)',              brand: 'Delhi Spice Market',   sku: 'DSM-002', shortDesc: 'Freshly stone-ground garam masala blend',                     fullDesc: 'Our signature garam masala, freshly stone-ground in small batches. A blend of 8 aromatic spices roasted to perfection. No preservatives or artificial colours.',                                                                                              price: 24900,   discount: 0,  stock: 100, rating: 4.5, reviews: 203, imgIds: [425, 428],     colors: [] },
      { shopIdx: 4, catId: catDryFruits.id, name: 'Premium Pistachio Kernels – 500g',               brand: 'Delhi Spice Market',   sku: 'DSM-003', shortDesc: 'Iranian pistachio kernels, lightly salted',                   fullDesc: 'Premium grade Iranian pistachio kernels, lightly roasted and salted. Rich green colour, perfect for snacking or garnishing desserts.',                                                                                                                        price: 179900,  discount: 8,  stock: 45,  rating: 4.4, reviews: 78, imgIds: [102, 108],      colors: [] },
      { shopIdx: 4, catId: catWhole.id,     name: 'Biryani Masala – Restaurant Grade (200g)',        brand: 'Delhi Spice Market',   sku: 'DSM-004', shortDesc: 'Secret recipe biryani masala used in top Delhi restaurants',   fullDesc: 'The same biryani masala blend used in top Delhi restaurants. A complex blend of 16 spices slow-roasted and ground to perfection. Just 2 tablespoons per kg of rice.',                                                                                         price: 29900,   discount: 0,  stock: 120, rating: 4.8, reviews: 342, imgIds: [430, 432],     colors: [] },

      // ── Shop 5: Heritage Silk & Textiles ────────────────────────────────────
      { shopIdx: 5, catId: catTextiles.id,  name: 'Banarasi Silk Saree – Bridal Collection',        brand: 'Heritage Silk',        sku: 'HS-001',  shortDesc: 'Handwoven Banarasi silk with real zari work',                 fullDesc: 'An exquisite bridal Banarasi saree handwoven with pure silk and real gold/silver zari. Features the traditional buti pattern with an ornate pallu. Takes 30 days to weave. Length: 6.3m with blouse piece.',                                                   price: 4999900, discount: 0,  stock: 5,   rating: 4.9, reviews: 15, imgIds: [335, 336],      colors: [['Red & Gold','#FF0000'],['Magenta & Gold','#FF00FF'],['Royal Purple','#7851A9']] },
      { shopIdx: 5, catId: catTextiles.id,  name: 'Chanderi Silk Cotton Saree',                     brand: 'Heritage Silk',        sku: 'HS-002',  shortDesc: 'Lightweight Chanderi saree with golden border',               fullDesc: 'Elegant Chanderi silk-cotton blend saree. Known for its sheer texture and light weight, perfect for summer occasions. Features a subtle golden zari border. Length: 5.5m with blouse piece.',                                                                 price: 299900,  discount: 20, stock: 20,  rating: 4.5, reviews: 42, imgIds: [337, 338],      colors: [['Peach','#FFDAB9'],['Sky Blue','#87CEEB'],['Mint Green','#98FF98']] },
      { shopIdx: 5, catId: catTextiles.id,  name: 'Handloom Pashmina Shawl – Tussar Silk',          brand: 'Heritage Silk',        sku: 'HS-003',  shortDesc: 'Natural tussar silk shawl with hand-block print',             fullDesc: 'A unique combination of Tussar silk and light pashmina. Features Mughal-inspired hand-block printing. Naturally dyed with vegetable colours.',                                                                                                                price: 549900,  discount: 10, stock: 15,  rating: 4.6, reviews: 23, imgIds: [399, 396],      colors: [['Earthy Brown','#8B7355'],['Mustard','#FFDB58']] },
      { shopIdx: 5, catId: catSilkShawl.id, name: 'Embroidered Dupatta – Chikankari',               brand: 'Heritage Silk',        sku: 'HS-004',  shortDesc: 'Lucknowi Chikankari hand-embroidered dupatta',                fullDesc: 'Delicate Chikankari embroidery on pure georgette dupatta. Traditional Lucknowi craftsmanship in contemporary pastels. Size: 250x110cm.',                                                                                                                      price: 199900,  discount: 0,  stock: 25,  rating: 4.4, reviews: 36, imgIds: [401, 404],      colors: [['White on White','#FFFFFF'],['Pink on Cream','#FFB6C1']] },

      // ── Shop 6: Mumbai Artisan Collective ───────────────────────────────────
      { shopIdx: 6, catId: catJewelry.id,   name: 'Oxidized Silver Jhumka Earrings',                brand: 'Mumbai Artisan',       sku: 'MA-001',  shortDesc: 'Handcrafted oxidized silver tribal jhumkas',                  fullDesc: 'Bold, statement jhumka earrings handcrafted in oxidized silver. Inspired by tribal art motifs. Hypoallergenic, lightweight (12g each). Length: 6cm.',                                                                                                         price: 149900,  discount: 15, stock: 30,  rating: 4.5, reviews: 58, imgIds: [238, 239],      colors: [['Antique Silver','#C0C0C0']] },
      { shopIdx: 6, catId: catJewelry.id,   name: 'Brass & Gemstone Statement Necklace',            brand: 'Mumbai Artisan',       sku: 'MA-002',  shortDesc: 'Boho-chic brass necklace with turquoise stones',             fullDesc: 'A show-stopping necklace combining aged brass with genuine turquoise stones. Each piece is uniquely handcrafted. Chain length adjustable: 18-22 inches.',                                                                                                     price: 249900,  discount: 0,  stock: 12,  rating: 4.7, reviews: 22, imgIds: [240, 241],      colors: [['Brass & Turquoise','#40E0D0']] },
      { shopIdx: 6, catId: catWoodcraft.id, name: 'Hand-painted Terracotta Planter Set',             brand: 'Mumbai Artisan',       sku: 'MA-003',  shortDesc: 'Set of 3 terracotta planters with Warli art',                fullDesc: 'Set of three terracotta planters hand-painted with traditional Warli art motifs. Sizes: 4", 6", and 8". Includes drainage holes. Weather-resistant finish.',                                                                                                  price: 179900,  discount: 10, stock: 18,  rating: 4.3, reviews: 31, imgIds: [174, 176],      colors: [['Terracotta & White','#E2725B']] },
      { shopIdx: 6, catId: catJewelry.id,   name: 'Sterling Silver Toe Ring Set',                    brand: 'Mumbai Artisan',       sku: 'MA-004',  shortDesc: 'Set of 4 adjustable sterling silver toe rings',              fullDesc: 'Four unique sterling silver toe rings with traditional motifs. Adjustable fit, 925 hallmarked silver. Beautifully packaged in a cloth pouch.',                                                                                                                price: 89900,   discount: 0,  stock: 40,  rating: 4.2, reviews: 45, imgIds: [238, 242],      colors: [['Sterling Silver','#C0C0C0']] },

      // ── Shop 7: Bangalore Organic Store ─────────────────────────────────────
      { shopIdx: 7, catId: catTea.id,       name: 'Nilgiri Organic Green Tea – 100 Teabags',        brand: 'Bangalore Organic',    sku: 'BO-001',  shortDesc: 'Single-origin Nilgiri green tea, USDA organic',              fullDesc: 'Certified organic green tea from Nilgiri hills. Smooth, low-caffeine blend with natural antioxidants. Each box contains 100 unbleached paper teabags.',                                                                                                       price: 49900,   discount: 10, stock: 80,  rating: 4.6, reviews: 134, imgIds: [225, 226],     colors: [] },
      { shopIdx: 7, catId: catTea.id,       name: 'Assam CTC Chai – Premium Breakfast (500g)',      brand: 'Bangalore Organic',    sku: 'BO-002',  shortDesc: 'Strong malty CTC tea from upper Assam estates',              fullDesc: 'Premium CTC (crush, tear, curl) tea from upper Assam. Bold, malty flavour perfect for masala chai. Sourced directly from small-holder farms. Rainforest Alliance certified.',                                                                                 price: 34900,   discount: 0,  stock: 100, rating: 4.5, reviews: 98,  imgIds: [221, 222],     colors: [] },
      { shopIdx: 7, catId: catDryFruits.id, name: 'Raw Honey – Wild Forest (500g)',                 brand: 'Bangalore Organic',    sku: 'BO-003',  shortDesc: 'Unprocessed wild forest honey from Western Ghats',           fullDesc: 'Raw, unfiltered honey collected from wild beehives in the Western Ghats. No heating, no blending. Rich in enzymes and pollen. Glass jar packaging.',                                                                                                         price: 59900,   discount: 0,  stock: 50,  rating: 4.8, reviews: 87,  imgIds: [312, 315],     colors: [] },
      { shopIdx: 7, catId: catSpices.id,    name: 'Cold-pressed Virgin Coconut Oil – 1L',           brand: 'Bangalore Organic',    sku: 'BO-004',  shortDesc: 'Farm-fresh cold-pressed coconut oil from Kerala',            fullDesc: 'Pure virgin coconut oil, cold-pressed from fresh Kerala coconuts within 24 hours of harvesting. Retains natural aroma and nutrients. Multi-use: cooking, skin, and hair.',                                                                                    price: 44900,   discount: 15, stock: 60,  rating: 4.7, reviews: 112, imgIds: [317, 318],     colors: [] },
      { shopIdx: 7, catId: catSpices.id,    name: 'Organic Turmeric Powder – Lakadong (200g)',      brand: 'Bangalore Organic',    sku: 'BO-005',  shortDesc: 'High-curcumin Lakadong turmeric from Meghalaya',             fullDesc: 'Lakadong variety turmeric with 7-12% curcumin content (regular turmeric has 2-3%). Organically grown in Meghalaya. Stone-ground, no additives.',                                                                                                              price: 29900,   discount: 0,  stock: 70,  rating: 4.6, reviews: 76,  imgIds: [425, 429],     colors: [] },

      // ── Extra products for variety ──────────────────────────────────────────
      { shopIdx: 0, catId: catSilkShawl.id, name: 'Cashmere Poncho – Modern Drape',                brand: 'Kashmir Shawl House',   sku: 'KSH-005', shortDesc: 'Contemporary cashmere poncho with tassel trim',               fullDesc: 'A modern take on Kashmiri craftsmanship. Pure cashmere poncho with hand-knotted tassel trim. One size fits all. Perfect layering piece for autumn.',                                                                                                         price: 599900,  discount: 20, stock: 15,  rating: 4.4, reviews: 17, imgIds: [406, 408],      colors: [['Oatmeal','#D2B48C'],['Burgundy','#800020']] },
      { shopIdx: 1, catId: catDryFruits.id, name: 'Mixed Dry Fruit Trail Mix – 750g',               brand: 'Saffron Garden',       sku: 'SG-006',  shortDesc: 'Almonds, cashews, raisins, apricots & figs',                 fullDesc: 'A healthy snacking mix of Kashmiri almonds, cashews, golden raisins, dried apricots, and anjeer (figs). No sugar, no salt. Vacuum-packed for freshness.',                                                                                                     price: 99900,   discount: 0,  stock: 60,  rating: 4.5, reviews: 48, imgIds: [102, 109],      colors: [] },
      { shopIdx: 2, catId: catWoodcraft.id, name: 'Cricket Bat – English Willow Kashmir Grade 1',   brand: 'Woodcraft Kashmir',    sku: 'WK-005',  shortDesc: 'Premium English Willow bat crafted in Kashmir',              fullDesc: 'Grade 1 English Willow cricket bat handcrafted by expert bat makers in Kashmir. 6-8 straight grains, lightweight pickup. Comes pre-knocked and ready to play.',                                                                                               price: 899900,  discount: 5,  stock: 8,   rating: 4.7, reviews: 34, imgIds: [178, 179],      colors: [['Natural','#F5DEB3']] },
      { shopIdx: 4, catId: catWhole.id,     name: 'Kashmiri Red Chilli Powder – 200g',              brand: 'Delhi Spice Market',   sku: 'DSM-005', shortDesc: 'Mild heat, deep red colour – Kashmiri Mirch',                fullDesc: 'Authentic Kashmiri red chilli powder. Known for its vibrant red colour with mild heat. The secret behind restaurant-quality tandoori dishes. Sun-dried and stone-ground.',                                                                                     price: 19900,   discount: 0,  stock: 90,  rating: 4.6, reviews: 189, imgIds: [430, 434],     colors: [] },
      { shopIdx: 5, catId: catTextiles.id,  name: 'Phulkari Dupatta – Punjab Handloom',             brand: 'Heritage Silk',        sku: 'HS-005',  shortDesc: 'Vibrant Phulkari embroidery on cotton base',                 fullDesc: 'Traditional Punjabi Phulkari dupatta with dense thread-work covering the entire fabric. A burst of colour in traditional floral patterns. Cotton base, lightweight. Size: 250x110cm.',                                                                       price: 179900,  discount: 10, stock: 18,  rating: 4.5, reviews: 27, imgIds: [335, 339],      colors: [['Multi Red','#FF4500'],['Multi Yellow','#FFD700']] },
      { shopIdx: 6, catId: catJewelry.id,   name: 'Kundan Choker Necklace Set',                     brand: 'Mumbai Artisan',       sku: 'MA-005',  shortDesc: 'Traditional Kundan set with earrings and maang tikka',       fullDesc: 'A complete traditional Kundan jewelry set: choker necklace, matching earrings, and maang tikka. Gold-plated brass with kundan stones. Adjustable back chain.',                                                                                                price: 349900,  discount: 0,  stock: 10,  rating: 4.8, reviews: 19, imgIds: [238, 243],      colors: [['Gold & Emerald','#50C878'],['Gold & Ruby','#E0115F']] },
      { shopIdx: 7, catId: catTea.id,       name: 'Chamomile & Lavender Sleep Tea – 30 bags',       brand: 'Bangalore Organic',    sku: 'BO-006',  shortDesc: 'Calming herbal blend for restful sleep',                     fullDesc: 'A soothing caffeine-free blend of chamomile flowers, lavender buds, and passionflower. Promotes relaxation and better sleep. 30 individually wrapped teabags.',                                                                                               price: 34900,   discount: 0,  stock: 55,  rating: 4.4, reviews: 63, imgIds: [225, 227],      colors: [] },
    ];

    const productRecords = [];
    for (const p of productsData) {
      const product = await Product.create({
        shopId: shopRecords[p.shopIdx].id,
        categoryId: p.catId,
        name: p.name,
        brand: p.brand,
        sku: p.sku,
        shortDescription: p.shortDesc,
        completeDescription: p.fullDesc,
        priceInPaise: p.price,
        discountPercent: p.discount,
        stockQuantity: p.stock,
        available: true,
        avgRating: p.rating,
        reviewCount: p.reviews,
      });

      // Images
      for (let i = 0; i < p.imgIds.length; i++) {
        await ProductImage.create({
          productId: product.id,
          url: pImg(p.imgIds[i], 600, 600),
          displayOrder: i,
          isPrimary: i === 0,
        });
      }

      // Colors
      for (const [colorName, hexCode] of p.colors) {
        await ProductColor.create({
          productId: product.id,
          colorName,
          hexCode,
        });
      }

      productRecords.push(product);
    }
    console.log(`🛍️  ${productRecords.length} products created with images & colors`);

    // ═══════════════════════════════════════════════════════════════════════════
    // 8. REVIEWS (realistic reviews for popular products)
    // ═══════════════════════════════════════════════════════════════════════════
    const reviewTexts = [
      { rating: 5, title: 'Absolutely stunning!',              body: 'The quality exceeded my expectations. Packaging was excellent and delivery was prompt. Highly recommend!' },
      { rating: 5, title: 'Worth every penny',                 body: 'Premium quality product. You can feel the craftsmanship. Will definitely order again from this shop.' },
      { rating: 4, title: 'Very good quality',                 body: 'Good product overall. Slightly different shade than shown in photos but still beautiful. Happy with my purchase.' },
      { rating: 4, title: 'Great gift option',                 body: 'Bought this as a gift and the recipient loved it! The packaging made it look very premium.' },
      { rating: 5, title: 'Authentic and genuine',             body: 'As someone who knows Kashmiri products, I can confirm this is the real deal. Authentic craftsmanship.' },
      { rating: 3, title: 'Good but could be better',          body: 'Product is decent for the price. Expected slightly better quality based on the description.' },
      { rating: 5, title: 'Beautiful craftsmanship',           body: 'The attention to detail is incredible. Each stitch tells a story. Museum-quality work!' },
      { rating: 4, title: 'Lovely product',                    body: 'Very happy with this purchase. The colours are vibrant and the material feels luxurious.' },
      { rating: 5, title: 'Best purchase this year',           body: 'I have been looking for something like this for ages. Finally found the perfect piece. Thank you Nearzy!' },
      { rating: 4, title: 'Nice quality, fast delivery',       body: 'Received within 3 days. Product matches the description. Would recommend to friends.' },
      { rating: 5, title: 'Exceeded expectations!',            body: 'Absolutely love it! The product is even more beautiful in person than in the pictures.' },
      { rating: 3, title: 'Decent product',                    body: 'It is okay for the price. Nothing extraordinary but serves its purpose well.' },
    ];

    let reviewCount = 0;
    // Add 2-4 reviews per product for the first 20 products
    for (let pIdx = 0; pIdx < Math.min(20, productRecords.length); pIdx++) {
      const numReviews = rnd(2, 4);
      const usedCustomers = new Set();
      for (let r = 0; r < numReviews; r++) {
        let custIdx;
        do { custIdx = rnd(0, customerRecords.length - 1); } while (usedCustomers.has(custIdx));
        usedCustomers.add(custIdx);
        const rev = pick(reviewTexts);
        try {
          await Review.create({
            productId: productRecords[pIdx].id,
            customerId: customerRecords[custIdx].id,
            rating: rev.rating,
            title: rev.title,
            body: rev.body,
          });
          reviewCount++;
        } catch { /* skip if duplicate */ }
      }
    }
    console.log(`⭐ ${reviewCount} reviews created`);

    // ═══════════════════════════════════════════════════════════════════════════
    // 9. SAMPLE ORDERS
    // ═══════════════════════════════════════════════════════════════════════════
    const addresses = await Address.findAll();
    const orderStatuses = ['PLACED', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'DELIVERED'];
    const paymentStatuses = ['PAID', 'PAID', 'PAID', 'PENDING'];

    let orderCount = 0;
    for (let i = 0; i < 8; i++) {
      const custIdx = i % customerRecords.length;
      const addr = addresses.find(a => String(a.customerId) === String(customerRecords[custIdx].id)) || addresses[0];
      const numItems = rnd(1, 3);
      const selectedProducts = [];
      for (let j = 0; j < numItems; j++) {
        selectedProducts.push(productRecords[rnd(0, productRecords.length - 1)]);
      }

      let totalPaise = 0;
      let totalDiscount = 0;
      const itemsPayload = selectedProducts.map(p => {
        const qty = rnd(1, 2);
        const unitPrice = p.priceInPaise;
        const discPaise = Math.round(unitPrice * p.discountPercent / 100);
        totalPaise += unitPrice * qty;
        totalDiscount += discPaise * qty;
        return { product: p, qty, unitPrice, discPaise };
      });

      const daysAgo = rnd(1, 30);
      const orderNum = `NRZ-${Date.now()}-${String(i + 1).padStart(4, '0')}`;
      const order = await OrderRecord.create({
        customerId: customerRecords[custIdx].id,
        shippingAddressId: addr.id,
        orderNumber: orderNum,
        totalAmountPaise: totalPaise - totalDiscount,
        discountAmountPaise: totalDiscount,
        status: pick(orderStatuses),
        paymentStatus: pick(paymentStatuses),
      });

      for (const item of itemsPayload) {
        await OrderItem.create({
          orderId: order.id,
          productId: item.product.id,
          shopId: item.product.shopId,
          quantity: item.qty,
          unitPricePaise: item.unitPrice,
          discountPaise: item.discPaise,
        });
      }
      orderCount++;
    }
    console.log(`📦 ${orderCount} orders created`);

    console.log('\n🎉 Seed complete! All demo user password: Test@1234');
    process.exit(0);
  } catch (err) {
    console.error('❌ Seed failed:', err);
    process.exit(1);
  }
}

seed();
