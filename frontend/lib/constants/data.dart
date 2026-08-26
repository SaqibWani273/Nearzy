// import 'package:flutter/material.dart';

// import '../../data/models/category/product_category.dart';
// import '../../data/models/category/clothing_fashion.dart';
// import '../../data/models/category/footwear.dart';
// import '/data/models/product/product_model.dart';
// import '/data/models/shop_model.dart';

// List<Product> featuredItems = [
//   ClothingFashionProduct(
//     id: "f_l_jacket_001",
//     name: "Leather Jackets",
//     images: ["assets/images/featured_items/Leather jackets.png"],
//     price: 1000,
//     discountInPercentage: 10, // 10% discount (dummy data)
//     completeDescription:
//         "Stay warm and stylish with our high-quality leather jackets. Made from premium materials, these jackets are perfect for any occasion. This particular jacket is a classic biker style in black color.",
//     shortDescription: "Classic biker style leather jacket",
//     brand: "Topstitch",
//     colors: [Colors.black, Colors.brown], // Sample colors
//     sizes: ["S", "M", "L", "XL"], // Sample sizes
//     shopId: "s_001", // Dummy shop ID
//     stockQuantity: 50, // Dummy stock quantity
//     rating: 4.8, // Dummy rating out of 5
//     category: CategoryType.clothingAndFashion,
//     reviews: reviews,
//   ),
//   ClothingFashionProduct(
//     id: "f_d_jacket_002",
//     name: "Denim Jackets",
//     images: ["assets/images/featured_items/Denim jackets.png"],
//     price: 800,
//     discountInPercentage: null, // No discount (dummy data)
//     completeDescription:
//         "A timeless classic, denim jackets are a must-have for any wardrobe. Our selection offers a variety of washes and styles to suit your taste. This one is a light blue wash with a relaxed fit.",
//     shortDescription: "Light blue wash denim jacket (relaxed fit)",
//     brand: "DenimCo",
//     colors: [Colors.lightBlue], // Sample color
//     sizes: ["XS", "S", "M", "L", "XL"], // Sample sizes
//     shopId: "s_002", // Dummy shop ID
//     stockQuantity: 100, // Dummy stock quantity
//     rating: 4.2, // Dummy rating out of 5
//     category: CategoryType.clothingAndFashion,
//     reviews: reviews,
//   ),
//   ClothingFashionProduct(
//     id: "f_wool_coat_003",
//     name: "Wool Coat",
//     images: ["assets/images/featured_items/wool coats.png"],
//     price: 1500,
//     discountInPercentage: 5, // 5% discount (dummy data)
//     completeDescription:
//         "Wrap yourself in luxury with our soft and cozy wool coat. Made from 100% merino wool, this coat is perfect for the colder months and will keep you warm and stylish. It features a classic double-breasted design and comes in a beautiful camel color.",
//     shortDescription: "Double-breasted wool coat (camel color)",
//     brand: "Warmspace",
//     colors: [Colors.lime], // Sample color
//     sizes: ["S", "M", "L", "XL"], // Sample sizes
//     shopId: "s_003", // Dummy shop ID
//     stockQuantity: 20, // Dummy stock quantity
//     rating: 4.9, // Dummy rating out of 5
//     category: CategoryType.clothingAndFashion,
//     reviews: reviews,
//   ),
//   ClothingFashionProduct(
//     id: "f_dress_004",
//     name: "Floral Print Dress",
//     images: ["assets/images/featured_items/Dresses.png"],
//     price: 750,
//     discountInPercentage: null, // No discount (dummy data)
//     completeDescription:
//         "Find the perfect dress for any occasion with our extensive collection. This dress features a beautiful floral print on a soft and flowy fabric. It's perfect for a summer day or a dressed-up evening.",
//     shortDescription: "Floral print dress (summer/evening)",
//     brand: "DressMe",
//     colors: [
//       Colors.deepOrange
//     ], // Sample color (replace with actual color information)
//     sizes: ["XS", "S", "M", "L"], // Sample sizes
//     shopId: "s_004", // Dummy shop ID
//     stockQuantity: 85, // Dummy stock quantity
//     rating: 4.7, // Dummy rating out of 5
//     category: CategoryType.clothingAndFashion,
//     reviews: reviews,
//   ),
//   FootwearProduct(
//     id: "m_sneakers_006",
//     name: "Sneakers",
//     images: [
//       "assets/images/more_products/4.png",
//       "assets/images/more_products/4.png",
//       "assets/images/more_products/4.png"
//     ],
//     colors: [Colors.black, Colors.white, Colors.blue],
//     price: 1480,
//     discountInPercentage: null, // Assuming no discount (set if needed)
//     completeDescription:
//         "Complete your outfit with a stylish pair of boots. These ankle boots are made from high-quality leather and feature a comfortable block heel. They're perfect for everyday wear or a night out.",
//     shortDescription: "Leather ankle boots (block heel)",
//     brand: "Shoetopia",
//     shopId: "...", // Shop ID (if applicable)
//     stockQuantity: 45, // Stock quantity (if applicable)
//     rating: 4.5, // Rating (if applicable)
//     category: CategoryType.footwear,
//     isWaterResistant:
//         false, // Assuming not water resistant (replace with actual value)
//     isLighWeight: true, // Assuming lightweight (replace with actual value)
//     occasion: Occasion.casual, // Assuming casual (replace with actual value)
//     soleMaterial: SoleMaterial.rubber, // Replace with actual sole material
//     upperMaterial: UpperMaterial.mesh, // Replace with actual upper material
//     closureType: ClosureType.laces, // Replace with actual closure type
//     reviews: reviews,
//   ),
// ];

// List<Product> moreProducts = [
//   FootwearProduct(
//     id: "m_sneakers_006",
//     name: "Running Sneakers",
//     images: [
//       "assets/images/more_products/4.png",
//       "assets/images/more_products/4.png",
//       "assets/images/more_products/4.png"
//     ],
//     colors: [
//       Colors.blue,
//       Colors.red,
//       Colors.green,
//       Colors.yellow,
//       Colors.blue,
//       Colors.red,
//       Colors.green,
//       Colors.yellow,
//       Colors.blue,
//       Colors.red,
//       Colors.green,
//       Colors.yellow,
//       Colors.blue,
//       Colors.red,
//       Colors.green,
//       Colors.yellow
//     ],
//     price: 1480,
//     discountInPercentage: null, // Assuming no discount (set if needed)
//     // Shop ID (if applicable)
//     completeDescription:
//         "These lightweight running sneakers are perfect for your daily jogs or workouts. The breathable mesh upper keeps your feet cool, while the rubber sole provides excellent traction. The lace closure ensures a snug and comfortable fit.",
//     shortDescription: "Lightweight, breathable running sneakers (mesh, laces)",
//     brand: "ActiveStride",
//     stockQuantity: 45, // Stock quantity (if applicable)
//     rating: 4.5, // Rating (if applicable)
//     category: CategoryType.footwear,
//     isWaterResistant:
//         false, // Assuming not water resistant (replace with actual value)
//     isLighWeight: true, // Assuming lightweight (replace with actual value)
//     occasion: Occasion.casual, // Assuming casual (replace with actual value)
//     soleMaterial: SoleMaterial.rubber, // Replace with actual sole material
//     upperMaterial: UpperMaterial.mesh, // Replace with actual upper material
//     closureType: ClosureType.laces,
//     shopId: '', // Replace with actual closure type
//     reviews: reviews,
//   ),
//   ClothingFashionProduct(
//     id: "m_backpack_007",
//     name: "Backpack",
//     images: ["assets/images/more_products/2.png"],
//     reviews: reviews,
//     price: 198,
//     discountInPercentage: null, // Assuming no discount (set if needed)
//     completeDescription:
//         "Carry all your essentials in style with our durable and comfortable backpacks. Perfect for school, work, or travel.",
//     shortDescription: "Carry all your essentials in style",
//     brand: "...", // Brand name (replace with actual brand)
//     colors: [
//       Colors.yellow,
//       Colors.black,
//       Colors.green,
//       Colors.red
//     ], // Sample color (replace with actual colors)
//     sizes: ["M", "L"], // Sample sizes (adjust for backpack sizes)
//     shopId: "...", // Shop ID (if applicable)
//     stockQuantity: 45, // Stock quantity (if applicable)
//     rating: 4.5, // Rating (if applicable)
//     category: CategoryType.accessories, // Set the category
//   ),
//   ClothingFashionProduct(
//     id: "m_laptop_case_008",
//     name: "Laptop Case",
//     images: ["assets/images/more_products/3.png"],
//     price: 78,
//     discountInPercentage: null, // Assuming no discount (set if needed)
//     completeDescription:
//         "Protect your laptop in style with our sleek and functional laptop cases. Available in a variety of sizes to fit most laptops.",
//     shortDescription: "Sleek and functional laptop case",
//     brand: "...", // Brand name (replace with actual brand)
//     colors: [Colors.grey], // Sample color (replace with actual colors)
//     shopId: "...", // Shop ID (if applicable)
//     stockQuantity: 34, // Stock quantity (if applicable)
//     rating: 3.6, // Rating (if applicable)
//     category: CategoryType.accessories, sizes: [], // Set the category
//     reviews: reviews,
//   ),
// ];

// List<Product> topPicksForYou = [
//   ClothingFashionProduct(
//     id: "t_white_dress_009",
//     name: "White Dress",
//     images: ["assets/images/top_picks/1.png"],
//     price: 1980,
//     discountInPercentage: 20, // Assuming discount calculation function exists
//     completeDescription:
//         "This stunning white dress, made from premium cotton, is perfect for any special occasion. It features a flattering A-line silhouette and delicate lace details. Turn heads with this timeless piece.",
//     shortDescription: "A-line silhouette, lace details (white dress)",
//     brand: "Le Blanc", // Sample brand name
//     colors: [Colors.white], // Sample color
//     reviews: reviews,
//     sizes: ["S", "M", "L"], // Sample sizes
//     shopId: "s_featured_001", // Dummy shop ID
//     stockQuantity: 20, // Dummy stock quantity
//     rating: 4.9, // Dummy rating out of 5
//     category: CategoryType.clothingAndFashion,
//   ),
//   ClothingFashionProduct(
//     id: "t_floral_dress_010",
//     name: "Floral Print Dress",
//     images: ["assets/images/top_picks/2.png"],
//     price: 1700,
//     discountInPercentage: 10, // Assuming discount calculation function exists
//     completeDescription:
//         "Embrace your feminine side with this beautiful floral print dress in vibrant shades of pink and blue. The playful pattern is perfect for spring and summer. This dress is sure to become a favorite in your wardrobe.",
//     shortDescription: "Pink & blue floral print (floral dress)",
//     brand: "Summer Breeze", // Sample brand name
//     colors: [Color.fromARGB(255, 220, 112, 148)], // Sample color (lighter pink)
//     sizes: ["XS", "S", "M", "L"], // Sample sizes
//     shopId: "s_featured_002", // Dummy shop ID
//     stockQuantity: 35, // Dummy stock quantity
//     rating: 4.7, // Dummy rating out of 5
//     category: CategoryType.clothingAndFashion,
//     reviews: reviews,
//   ),
// ];

// List<Product> trendingNow = [
//   ClothingFashionProduct(
//     id: "tn_gucci_bag_011",
//     name: "Gucci Bag",
//     images: ["assets/images/trending_now/1.png"],
//     reviews: reviews,
//     price: 4200,
//     discountInPercentage: 8, // Assuming discount calculation function exists
//     completeDescription:
//         "Make a statement with this iconic Gucci bag, crafted from genuine Italian leather. The timeless design features a structured silhouette and gold-tone hardware. Be the envy of everyone with this must-have piece.",
//     shortDescription: "Structured silhouette, gold hardware (Gucci bag)",
//     brand: "Gucci",
//     colors: [Colors.brown[200]!], // Sample color (lighter brown)
//     shopId: "s_luxury_001", // Dummy shop ID
//     stockQuantity: 5, // Dummy stock quantity (limited edition)
//     rating: 4.8, // Dummy rating out of 5
//     category: CategoryType.accessories, sizes: [], // Category for bags
//   ),
//   ClothingFashionProduct(
//     id: "tn_gucci_bag_011",
//     name: "Gucci Bag",
//     images: ["assets/images/trending_now/1.png"],
//     price: 4200,
//     discountInPercentage: 8, // Assuming discount calculation function exists
//     completeDescription:
//         "Make a statement with this iconic Gucci bag, crafted from genuine Italian leather. The timeless design features a structured silhouette and gold-tone hardware. Be the envy of everyone with this must-have piece.",
//     shortDescription: "Structured silhouette, gold hardware (Gucci bag)",
//     brand: "Gucci",
//     colors: [Colors.brown[200]!], // Sample color (lighter brown)
//     shopId: "s_luxury_001", // Dummy shop ID
//     stockQuantity: 5, // Dummy stock quantity (limited edition)
//     rating: 4.8, // Dummy rating out of 5
//     category: CategoryType.accessories, sizes: [], // Category for bags
//     reviews: [],
//   ),
//   // ... add more trending products using ClothingFashionProduct
// ];
// List<Product> productsMayLike = [
//   // Consider replacing with a non-replica Gucci bag suggestion
//   ClothingFashionProduct(
//     id: "pml_satchel_bag_014", // Unique ID for satchel bag
//     name: "Satchel Bag",
//     images: ["assets/images/products_may_like/1.png"],
//     reviews: reviews,
//     price: 800, // Adjusted price for non-replica bag
//     discountInPercentage: null, // Assuming no discount (set if needed)
//     completeDescription:
//         "Look sharp with this stylish satchel bag. This bag is crafted from high-quality materials and features a timeless design. Elevate your everyday look at a more accessible price point.",
//     shortDescription: "Timeless design, satchel bag",
//     brand: "The Classy Collective", // Sample brand name
//     colors: [Colors.brown[100]!], // Sample color (lighter brown)
//     shopId: "s_accessories_003", // Dummy shop ID
//     stockQuantity: 18, // Dummy stock quantity
//     rating: 4.6, // Dummy rating out of 5
//     category: CategoryType.accessories, sizes: [],
//   ),
//   ClothingFashionProduct(
//     id: "pml_crossbody_bag_015", // Unique ID for crossbody bag
//     name: "Crossbody Bag",
//     images: ["assets/images/products_may_like/2.png"],
//     price: 150,
//     discountInPercentage: null, // Assuming no discount (set if needed)
//     completeDescription:
//         "Embrace classic elegance with this timeless crossbody bag. This affordable bag features a sophisticated design that is perfect for any occasion. Add a touch of luxury to your wardrobe without breaking the bank.",
//     shortDescription: "Sophisticated design, crossbody bag",
//     brand: "Everyday Essentials", // Sample brand name
//     colors: [Colors.black], // Sample color
//     shopId: "s_accessories_004", // Dummy shop ID
//     stockQuantity: 30, // Dummy stock quantity
//     rating: 4.3, // Dummy rating out of 5
//     category: CategoryType.accessories, sizes: [],
//     reviews: [],
//   ),
//   OtherProduct(
//     id: "pml_cannon_camera_016",
//     name: "Canon Camera",
//     images: ["assets/images/products_may_like/3.png"],
//     price: 200,
//     discountInPercentage: null, // Assuming no discount (set if needed)
//     completeDescription:
//         "Capture life's moments with this user-friendly Canon camera. This camera is packed with features that are perfect for capturing memories on the go. Take your first steps into the world of photography with this affordable and easy-to-use camera.",
//     shortDescription: "User-friendly, Canon camera",
//     brand: "Canon",
//     shopId: "s_electronics_001", // Dummy shop ID
//     stockQuantity: 10, // Dummy stock quantity
//     rating: 4.2, category: CategoryType.electronics,
//     colors: [], // Dummy rating out of 5
//     reviews: [],
//   ),
// ];

// //shop data

// List<ShopModel> popularShops = [
//   ShopModel(
//       name: "Shop 1", image: "assets/images/popular_shops/1.png", rating: 4.9),
//   ShopModel(
//       name: "Shop 2", image: "assets/images/popular_shops/2.png", rating: 4.8),
//   ShopModel(
//       name: "Shop 3", image: "assets/images/popular_shops/3.png", rating: 4.7),
//   ShopModel(
//       name: "Shop 1", image: "assets/images/popular_shops/1.png", rating: 4.9),
//   ShopModel(
//       name: "Shop 2", image: "assets/images/popular_shops/2.png", rating: 4.8),
//   ShopModel(
//       name: "Shop 3", image: "assets/images/popular_shops/3.png", rating: 4.7),
// ];
// List<ShopModel> topRatedShops = [
//   ShopModel(
//       name: "Shop 1",
//       image: "assets/images/top_rated_shops/1.png",
//       rating: 4.9),
//   ShopModel(
//       name: "Shop 2",
//       image: "assets/images/top_rated_shops/2.png",
//       rating: 4.8),
//   ShopModel(
//       name: "Shop 3",
//       image: "assets/images/top_rated_shops/3.png",
//       rating: 4.7),
// ];
// //change it later with the new enumType created
// List<Category> categories = [
//   Category(
//       name: "Shoes",
//       image: "assets/images/categories/shoes.png",
//       isTopCategory: false,
//       products: []),
//   Category(
//       name: "Bags",
//       image: "assets/images/categories/bags.png",
//       isTopCategory: false,
//       products: []),
//   Category(
//       name: "Jewelery",
//       image: "assets/images/categories/jewelery.png",
//       isTopCategory: false,
//       products: []),
//   Category(
//       name: "Clothing",
//       image: "assets/images/categories/clothing.png",
//       isTopCategory: false,
//       products: []),
//   Category(
//       name: "Sneakers",
//       image: "assets/images/categories/2.png",
//       isTopCategory: true,
//       products: []),
//   Category(
//       name: "KitchenWare",
//       image: "assets/images/categories/4.png",
//       isTopCategory: true,
//       products: []),
//   Category(
//       name: "Fashion",
//       image: "assets/images/categories/3.png",
//       isTopCategory: false,
//       products: []),
//   Category(
//       name: "Mobiles",
//       image: "assets/images/categories/mobiles.png",
//       isTopCategory: true,
//       products: []),
//   Category(
//       name: "Gifts",
//       image: "assets/images/categories/5 (1).png",
//       isTopCategory: true,
//       products: []),
//   Category(
//       name: "Bags",
//       image: "assets/images/categories/5 (2).png",
//       isTopCategory: true,
//       products: []),
//   Category(
//       name: "Furniture",
//       image: "assets/images/categories/5 (3).png",
//       isTopCategory: false,
//       products: []),
//   Category(
//       name: "Sports",
//       image: "assets/images/categories/5 (4).png",
//       isTopCategory: false,
//       products: []),
//   Category(
//       name: "Toys",
//       image: "assets/images/categories/5 (5).png",
//       isTopCategory: false,
//       products: []),
//   Category(
//       name: "Electronics",
//       image: "assets/images/categories/5 (6).png",
//       isTopCategory: false,
//       products: []),
// ];

// // Sample list of ProductReview objects
// final List<ProductReview> reviews = [
//   ProductReview(
//     id: "pr_123",
//     username: "HappyCustomer",
//     review:
//         "This product is amazing! It exceeded my expectations and is exactly what I was looking for. The quality is fantastic and it works perfectly. I would highly recommend this product to anyone.",
//     // image: "assets/images/reviews/review_1.jpg",
//     rating: 5,
//   ),
//   ProductReview(
//     id: "pr_456",
//     username: "TechEnthusiast",
//     review:
//         "This is a great product for the price. It's easy to use and has all the features I need. I'm very happy with my purchase.",
//     // image: null,
//     rating: 4,
//   ),
//   ProductReview(
//     id: "pr_789",
//     username: "Fashionista",
//     review:
//         "Love the style and design of this product! It's comfortable and well-made. I've gotten so many compliments on it.",
//     // // image: "assets/images/reviews/review_2.jpg",
//     rating: 5,
//   ),
//   ProductReview(
//     id: "pr_001",
//     username: "DisappointedBuyer",
//     review:
//         "This product was not what I expected. The quality is poor and it doesn't work properly. I'm very disappointed with this purchase.",
//     image: "assets/images/more_products/4.png",
//     rating: 1,
//   ),
//   ProductReview(
//     id: "pr_002",
//     username: "InconvenientUser",
//     review:
//         "This product is difficult to use and the instructions are unclear. I wouldn't recommend it to anyone.",
//     // image: null,
//     rating: 2,
//   ),
//   ProductReview(
//     id: "pr_003",
//     username: "StyleCritic",
//     review:
//         "The design of this product isn't very appealing to me. It also feels a bit cheap. I wouldn't buy it again.",
//     // image: "assets/images/reviews/review_4.jpg",
//     rating: 3,
//   ),
// ];
