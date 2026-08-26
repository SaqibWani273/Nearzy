/// Category of products within the application.
enum CategoryType {
  /// Clothing, apparel, and fashion accessories.
  /// This could include items like shirts, pants, dresses, hats, scarves, bags, etc.
  clothingAndFashion,

  /// Additional accessories that complement clothing or enhance an outfit.
  /// This could include items like belts, ties, jewelry, sunglasses, watches, etc.
  accessories,

  /// Shoes for all occasions.
  /// This could include sneakers, sandals, boots, heels, flats, etc.
  footwear,

  /// Products for personal care and beauty enhancement.
  /// This could include skincare, makeup, haircare, fragrances, bath & body products, etc.
  beautyAndPersonalCare,

  /// Electronic devices and appliances.
  /// This is a broad category and could be further sub-divided based on specific needs.
  electronics,

  /// Mobile phones and smartphones.
  /// This could include different brands, models, and accessories.
  mobiles,

  /// Portable computers, including laptops, ultrabooks, and Chromebooks.
  laptops,

  /// Timepieces for men and women.
  /// This could include wristwatches, pocket watches, and smartwatches.
  watches,

  /// Ornamental pieces worn for decoration.
  /// This could include necklaces, bracelets, earrings, rings, etc.
  jewellery,

  /// Products for the home and kitchen.
  /// This could include cookware, bakeware, utensils, appliances, storage solutions, etc.
  homeAndKitchen,

  /// Furniture and decorative items for the home.
  /// This could include sofas, beds, chairs, tables, lamps, rugs, artwork, etc.
  furnitureAndHomeDecor,

  /// Products for pets.
  /// This could include food, treats, toys, beds, leashes, collars, etc.
  pets,

  /// Books, stationery items, and writing supplies.
  /// This could include novels, textbooks, notebooks, pens, pencils, etc.
  booksAndStationery,

  /// Toys and games for children and adults.
  /// This could include board games, action figures, puzzles, stuffed animals, video games, etc.
  toysAndGames,

  /// Products for babies and children.
  /// This could include clothing, diapers, wipes, toys, strollers, car seats, etc.
  babyAndKids,

  /// Products for athletic activities and outdoor recreation.
  /// This could include clothing, footwear, equipment (sports balls, camping gear, etc.)
  sportsAndOutdoors,

  /// Tools and materials for home improvement and DIY projects.
  /// This could include hammers, saws, drills, paint, building materials, etc.
  homeImprovementAndTools,

  /// Car parts, accessories, and maintenance products.
  /// This could include tires, batteries, oil, car cleaning supplies, etc.
  carsAndAccessories,

  /// Supplies and materials used in manufacturing processes.
  /// This category might be specific to B2B applications.
  manufacturingSupplies,

  /// Unique, handcrafted products made by artisans.
  /// This could include jewelry, clothing, home decor items, etc.
  handMadeCrafts,
}
//create a switch statement that will return custom string name for each category

String categoryToString(CategoryType category) {
  switch (category) {
    case CategoryType.clothingAndFashion:
      return 'Fashion';
    case CategoryType.accessories:
      return 'Accessories';
    case CategoryType.footwear:
      return 'Footwear';
    case CategoryType.beautyAndPersonalCare:
      return 'Beauty';
    case CategoryType.electronics:
      return 'Electronics';
    case CategoryType.mobiles:
      return 'Mobiles';
    case CategoryType.laptops:
      return 'Laptops';
    case CategoryType.watches:
      return 'Watches';
    case CategoryType.jewellery:
      return 'Jewellery';
    case CategoryType.homeAndKitchen:
      return 'Home and Kitchen';
    case CategoryType.furnitureAndHomeDecor:
      return 'Home Decor';
    case CategoryType.pets:
      return 'Pets';
    case CategoryType.booksAndStationery:
      return 'Books & Stationery';
    case CategoryType.toysAndGames:
      return 'Toys & Games';
    case CategoryType.babyAndKids:
      return 'Baby & Kids';
    case CategoryType.sportsAndOutdoors:
      return 'Sports ';
    case CategoryType.homeImprovementAndTools:
      return 'Home Improvement and Tools';
    case CategoryType.carsAndAccessories:
      return 'Cars and Accessories';
    case CategoryType.manufacturingSupplies:
      return 'Manufacturing Supplies';
    case CategoryType.handMadeCrafts:
      return 'Hand Made Crafts';
  }
}
