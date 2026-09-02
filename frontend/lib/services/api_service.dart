import 'dart:convert';
import 'dart:developer';

import 'package:mca_project/data/models/order.dart';
import 'package:mca_project/data/models/category/product_category/product_category.dart';

import '/data/models/shop_model/shop_api_parser.dart';
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
  /// Base headers included on every request.
  /// The ngrok header bypasses the free-tier browser warning interstitial.
  static Map<String, String> _h([Map<String, String>? extra]) {
    final headers = <String, String>{
      'ngrok-skip-browser-warning': 'true',
    };
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  static Future<UserModel?> getUserModel() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await http.post(
        Uri.parse(ApiConst.userProfileUrl),
        headers: _h({"Authorization": "Bearer $token"}),
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
          headers: _h({"Content-Type": "application/json"}),
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
        headers: _h({"Content-Type": "application/json"}),
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
        headers: _h({"Content-Type": "application/json"}),
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
          headers: _h({
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }),
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
        headers: _h({"Content-Type": "application/json"}),
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
          headers: _h({"Content-Type": "application/json"}),
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
          headers: _h({"Content-Type": "application/json"}),
          body: jsonEncode({'username': username}));
      if (response.statusCode == 200) {
        return bool.fromEnvironment(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// The signed-in shop's inventory. The server resolves the shop from the
  /// bearer token, so [shopId] is only kept for call-site compatibility.
  static Future<List<Product>> fetchMyUploadedProducts(
    int shopId, {
    String? query,
    int page = 1,
    int limit = 100,
  }) =>
      _fetchProductPage(
        Uri.parse(ApiConst.shopMyProductsUrl).replace(
          queryParameters: {
            if (query != null && query.trim().length >= 2) 'q': query.trim(),
            'page': '$page',
            'limit': '$limit',
          },
        ),
        label: 'fetchMyUploadedProducts',
        authorized: true,
      );

  static Future<List<Order>> fetchMyOrders(int id, Roles role) async {
    List<Order> orders = [];
    return orders;
  }

  static Future<void> updateOrderStatus(
      {required String orderId, required String status}) async {
    // Graceful handling
  }

  /// Builds the location query the discovery endpoints expect.
  ///
  /// The parameter names matter: the server reads `latitude`/`longitude`, and
  /// the abbreviations this used to send were silently ignored, so every
  /// "nearby" request was really an unfiltered one.
  static Map<String, String> _locationQuery(
    LocationInfo? location, {
    double? radiusKm,
  }) {
    if (location == null || !location.hasCoordinates) return {};
    return {
      'latitude': '${location.latitude}',
      'longitude': '${location.longtitude}',
      if (radiusKm != null) 'radiusKm': '$radiusKm',
    };
  }

  /// Discovery endpoints answer with a `{total, page, shops|products}`
  /// envelope, not a bare array. Unwrap defensively so a shape change
  /// degrades to an empty list rather than a crash.
  static List<dynamic> _unwrap(dynamic decoded, String key) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final inner = decoded[key];
      if (inner is List) return inner;
    }
    return const [];
  }

  static Future<List<ShopModel1>> fetchNearbyShops(
    LocationInfo? location, {
    double radiusKm = 15,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final query = {
        ..._locationQuery(location, radiusKm: radiusKm),
        'page': '$page',
        'limit': '$limit',
      };
      final response = await http.get(
        Uri.parse(ApiConst.shopsNearLocationUrl)
            .replace(queryParameters: query),
        headers: _h({"Content-Type": "application/json"}),
      );

      if (response.statusCode != 200) {
        log("fetchNearbyShops -> ${response.statusCode} ${response.body}");
        return [];
      }

      // Parsed leniently: deployed servers may still return raw ORM rows,
      // whose field names differ from the DTO the generated parser expects.
      final shops = ShopApiParser.parseList(
        _unwrap(jsonDecode(response.body), 'shops'),
        originLat: location?.latitude,
        originLng: location?.longtitude,
      );
      // Nearest first, so the list agrees with the map even when the server
      // ordered alphabetically.
      shops.sort((a, b) =>
          (a.distanceKm ?? double.infinity)
              .compareTo(b.distanceKm ?? double.infinity));
      return shops;
    } catch (e) {
      log("fetchNearbyShops error: $e");
      return [];
    }
  }

  static Future<List<Product>> fetchLocationSpecialities(
      LocationInfo? location) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConst.locationSpecialitiesUrl)
            .replace(queryParameters: _locationQuery(location)),
        headers: _h({"Content-Type": "application/json"}),
      );
      if (response.statusCode != 200) {
        log("fetchLocationSpecialities -> ${response.statusCode}");
        return [];
      }
      return _unwrap(jsonDecode(response.body), 'products')
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    } catch (e) {
      log("fetchLocationSpecialities error: $e");
      return [];
    }
  }

  static Future<List<Product>> fetchAffordableProducts(
      LocationInfo? location) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConst.affordableProductsUrl)
            .replace(queryParameters: _locationQuery(location)),
        headers: _h({"Content-Type": "application/json"}),
      );
      if (response.statusCode != 200) {
        log("fetchAffordableProducts -> ${response.statusCode}");
        return [];
      }
      return _unwrap(jsonDecode(response.body), 'products')
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    } catch (e) {
      log("fetchAffordableProducts error: $e");
      return [];
    }
  }

  /// Shared fetch for the paginated product endpoints, all of which answer
  /// with a `{total, page, products}` envelope.
  static Future<List<Product>> _fetchProductPage(
    Uri uri, {
    required String label,
    bool authorized = false,
  }) async {
    try {
      final headers = _h({"Content-Type": "application/json"});
      if (authorized) {
        final token = await SecureStorage.getToken();
        if (token != null) headers["Authorization"] = "Bearer $token";
      }

      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        log("$label -> ${response.statusCode} ${response.body}");
        return [];
      }

      return _unwrap(jsonDecode(response.body), 'products')
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    } catch (e) {
      log("$label error: $e");
      return [];
    }
  }

  /// Products on discount nearby, deepest cut first.
  static Future<List<Product>> fetchDiscountedProducts(
    LocationInfo? location, {
    double radiusKm = 15,
    int page = 1,
    int limit = 40,
  }) =>
      _fetchProductPage(
        Uri.parse(ApiConst.discountedProductsUrl).replace(
          queryParameters: {
            ..._locationQuery(location, radiusKm: radiusKm),
            'page': '$page',
            'limit': '$limit',
          },
        ),
        label: 'fetchDiscountedProducts',
      );

  static Future<List<Product>> fetchProductsByShopId(
    int id, {
    int page = 1,
    int limit = 40,
  }) =>
      _fetchProductPage(
        Uri.parse(ApiConst.shopProductsUrl(id))
            .replace(queryParameters: {'page': '$page', 'limit': '$limit'}),
        label: 'fetchProductsByShopId',
      );

  static Future<List<Product>> fetchProductsByCategoryId(
    int id, {
    LocationInfo? location,
    double radiusKm = 15,
    int page = 1,
    int limit = 40,
  }) =>
      _fetchProductPage(
        Uri.parse(ApiConst.categoryProductsUrl(id)).replace(
          queryParameters: {
            ..._locationQuery(location, radiusKm: radiusKm),
            'page': '$page',
            'limit': '$limit',
          },
        ),
        label: 'fetchProductsByCategoryId',
      );

  static Future<List<Product>> searchProducts(
    String searchText, {
    LocationInfo? location,
    double radiusKm = 15,
    int page = 1,
    int limit = 40,
  }) {
    final term = searchText.trim();
    if (term.length < 2) return Future.value(const []);

    return _fetchProductPage(
      Uri.parse(ApiConst.searchProductsUrl).replace(
        queryParameters: {
          'q': term,
          ..._locationQuery(location, radiusKm: radiusKm),
          'page': '$page',
          'limit': '$limit',
        },
      ),
      label: 'searchProducts',
    );
  }

  // ── Admin APIs ────────────────────────────────────────────────────────
  static Future<void> adminLogin(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConst.adminLoginUrl),
      headers: _h({"Content-Type": "application/json"}),
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
      headers: _h({
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      }),
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
