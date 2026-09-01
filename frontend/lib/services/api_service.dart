import 'dart:convert';
import 'dart:developer';

import 'package:mca_project/data/models/order.dart';
import 'package:mca_project/data/models/category/product_category/product_category.dart';

import '/data/models/shop_model/shop_model1.dart';
import '/constants/rest_api_const.dart';
import '/utils/exceptions/custom_exception.dart';

import '../constants/bottom_navbar_items.dart';
import '../data/models/category/category_data.dart';
import '../data/models/customer.dart';
import '../data/models/product.dart';
import '../utils/secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<UserModel?> getUserModel() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await http.post(
        Uri.parse(ApiConst.userProfileUrl),
        headers: {"Authorization": "Bearer $token"},
        body: token,
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final decodedResponse = jsonDecode(response.body);
          if (decodedResponse['role'] == Roles.ROLE_CUSTOMER.name) {
            return Customer.fromMap(decodedResponse['model']);
          } else if (decodedResponse['role'] == Roles.ROLE_SHOP.name) {
            return ShopModel1.fromJson(decodedResponse['model']);
          }
        }
        log("Server did not return any data--> ${response.body}");
        return null;
      } else if (response.statusCode == 401) {
        await SecureStorage.deleteToken();
        return null;
      } else {
        log("${response.statusCode} -> ${response.body}");
        return null;
      }
    } catch (e) {
      log("getUserModel error: $e");
      return null;
    }
  }

  static Future<void> registerShop(ShopModel1 shopModel) async {
    try {
      final response = await http.post(Uri.parse(ApiConst.shopRegistrationUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(shopModel.toJson()));
      if (response.statusCode == 200) {
        log(response.body);
      } else {
        final String errorMessage =
            jsonDecode(response.body)["message"].toString();
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message:
                'Data Integrity Error! ${response.statusCode} -> ${errorMessage.length > 40 ? errorMessage.substring(0, 40) : errorMessage}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> loginShop(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConst.shopLoginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        await SecureStorage.storeToken(response.body);
      } else if (response.statusCode == 400) {
        throw CustomException(
            errorType: ErrorType.unknown, message: response.body);
      } else {
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message: "Something went wrong!,${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logoutShop() async {
    try {
      await SecureStorage.deleteToken();
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>?> loadAllCategories(Roles role) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConst.loadAllCategoriesUrl),
        headers: {
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        if (role == Roles.ROLE_CUSTOMER) {
          List<ProductCategory> categories = [];
          for (var element in jsonDecode(response.body)) {
            categories.add(ProductCategory.fromJson(element));
          }
          return categories;
        }
        var categoriesData = <CategoryData>[];
        for (var element in jsonDecode(response.body)) {
          categoriesData.add(CategoryData.fromJson(element));
        }
        return categoriesData;
      } else {
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message: "Something went wrong!,${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> uploadProduct(Product product) async {
    try {
      final String? token = await SecureStorage.getToken();
      final response = await http.post(Uri.parse(ApiConst.uploadProductUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode(product.toJson()));
      if (response.statusCode != 200) {
        final String errorMessage =
            jsonDecode(response.body)["message"].toString();
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message:
                "Server Error ->  ${response.statusCode} -> ${errorMessage.length > 40 ? errorMessage.substring(0, 40) : errorMessage}");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Product>> fetchProducts(
      LocationInfo? locationInfo, int currentPageKey) async {
    try {
      final response = await http.get(
        Uri.parse(
            "${ApiConst.fetchAllProductsUrl}?page=$currentPageKey&pageSize=${ApiConst.pageSize}"),
        headers: {
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final products = <Product>[];
        for (var element in jsonDecode(response.body)) {
          products.add(Product.fromJson(element));
        }
        return products;
      } else {
        log("server error in fetchProducts,response-> ${response.body} ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("fetchProducts error: $e");
      return [];
    }
  }

  static Future<List<ShopModel1>> fetchShops(LocationInfo? locationInfo) async {
    try {
      return await fetchNearbyShops(locationInfo);
    } catch (e) {
      log("fetchShops error: $e");
      return [];
    }
  }

  static Future<bool?> emailExists(String email) async {
    try {
      final response = await http.post(Uri.parse(ApiConst.emailExistsUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({'email': email}));
      if (response.statusCode == 200) {
        return bool.fromEnvironment(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> usernameExists(String username) async {
    try {
      final response = await http.post(Uri.parse(ApiConst.usernameExistsUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({'username': username}));
      if (response.statusCode == 200) {
        return bool.fromEnvironment(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Product>> fetchMyUploadedProducts(int shopId) async {
    List<Product> products = [];
    return products;
  }

  static Future<List<Order>> fetchMyOrders(int id, Roles role) async {
    List<Order> orders = [];
    return orders;
  }

  static Future<void> updateOrderStatus(
      {required String orderId, required String status}) async {
    // Graceful handling
  }

  static Future<List<ShopModel1>> fetchNearbyShops(
      LocationInfo? location) async {
    try {
      List<ShopModel1> shops = [];
      String query = location != null
          ? "?lat=${location.latitude}&lng=${location.longtitude}"
          : "";
      final response = await http.get(
        Uri.parse("${ApiConst.shopsNearLocationUrl}$query"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        for (var element in jsonDecode(response.body)) {
          shops.add(ShopModel1.fromJson(element));
        }
      }
      return shops;
    } catch (e) {
      log("fetchNearbyShops error: $e");
      return [];
    }
  }

  static Future<List<Product>> fetchLocationSpecialities(
      LocationInfo? location) async {
    try {
      List<Product> products = [];
      String query = location != null
          ? "?lat=${location.latitude}&lng=${location.longtitude}"
          : "";
      final response = await http.get(
        Uri.parse("${ApiConst.locationSpecialitiesUrl}$query"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        for (var element in jsonDecode(response.body)) {
          products.add(Product.fromJson(element));
        }
      }
      return products;
    } catch (e) {
      log("fetchLocationSpecialities error: $e");
      return [];
    }
  }

  static Future<List<Product>> fetchAffordableProducts(
      LocationInfo? location) async {
    try {
      List<Product> products = [];
      String query = location != null
          ? "?lat=${location.latitude}&lng=${location.longtitude}"
          : "";
      final response = await http.get(
        Uri.parse("${ApiConst.affordableProductsUrl}$query"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        for (var element in jsonDecode(response.body)) {
          products.add(Product.fromJson(element));
        }
      }
      return products;
    } catch (e) {
      log("fetchAffordableProducts error: $e");
      return [];
    }
  }

  static Future<List<Product>> fetchProductsByShopId(int id) async {
    return [];
  }

  static Future<List<Product>> fetchProductsByCategoryId(int id) async {
    return [];
  }

  static Future<List<Product>> searchProducts(String searchText) async {
    return [];
  }

  // ── Admin APIs ────────────────────────────────────────────────────────
  static Future<void> adminLogin(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConst.adminLoginUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      await SecureStorage.storeToken(response.body);
    } else {
      throw CustomException(
          errorType: ErrorType.unknown, message: 'Invalid admin credentials');
    }
  }

  static Future<void> adminAddCategory({
    required String name,
    required String description,
    required String image,
    required bool isTopProductCategory,
  }) async {
    final token = await SecureStorage.getToken();
    final response = await http.post(
      Uri.parse(ApiConst.adminAddCategoryUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'image': image,
        'isTopProductCategory': isTopProductCategory,
      }),
    );
    if (response.statusCode != 200) {
      throw CustomException(
          errorType: ErrorType.unknown, message: 'Failed to add category');
    }
  }
}
