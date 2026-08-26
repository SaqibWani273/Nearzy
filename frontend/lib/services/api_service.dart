import 'dart:convert';
import 'dart:developer';

import 'package:mca_project/data/models/Order.dart';
import 'package:mca_project/data/models/category/product_category/product_category.dart';

import '/data/models/shop_model/shop_model1.dart';

import '/constants/rest_api_const.dart';
import '/utils/exceptions/custom_exception.dart';

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
        //not logged in
        return null;
      }

      final response = await http.post(
        Uri.parse(ApiConst.userProfileUrl),
        headers: {"Authorization": "Bearer $token"},
        body: token,
      );

      if (response.statusCode == 200) {
        /* expected json response
       '{
         'role': 'customer',
         'model': {
           customer details....
                  }
        }'
                  or


        '{
         'role': 'shop',
         'model': {
           shop details.....
                  }
        }'
        
                  */
        if (response.body.isNotEmpty) {
          final decodedResponse = jsonDecode(response.body);
          if (decodedResponse['role'] == Roles.ROLE_CUSTOMER.name) {
            // return Customer.fromMap(decodedResponse['model']);
            return Customer.fromMap(decodedResponse['model']);
          }
          return ShopModel1.fromJson(decodedResponse['model']);
        }
        //server did not return any data
        log("Server did not return any data--> ${response.body}");
        return null;
      } else if (response.statusCode == 401) {
        //token expired
        await SecureStorage.deleteToken();
        //not logged in
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
        log(" error in  registerShop,response-> ${response.body} ${response.statusCode} -> ${response.body}");
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
            message: " Something went wrong!,${response.statusCode}");
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
      // final token = await SecureStorage.getToken();
      // if (token == null || token.isEmpty) {
      //   //not logged in
      //   return null;
      // }
      final response = await http.get(
        Uri.parse(ApiConst.loadAllCategoriesUrl),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer $token"
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
        //for shop
        var categoriesData = <CategoryData>[];
        for (var element in jsonDecode(response.body)) {
          categoriesData.add(CategoryData.fromJson(element));
        }
        return categoriesData;
      } else {
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message: " Something went wrong!,${response.statusCode}");
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
                " Sever Error ->  ${response.statusCode} -> ${errorMessage.length > 40 ? errorMessage.substring(0, 40) : errorMessage}");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Product>> fetchProducts(
      LocationInfo? locationInfo, int currentPageKey) async {
    try {
      // final response = await http.get(Uri.parse(ApiConst.fetchProductUrl));
      final response = await http.post(
        Uri.parse(ApiConst.getProductsByLocation),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "pageKey": currentPageKey,
          "location": locationInfo == null ? null : locationInfo.toJson()
        }),
      );
      // log(response.body);
      if (response.statusCode == 200) {
        final products = <Product>[];
        for (var element in jsonDecode(response.body)) {
          products.add(Product.fromJson(element));
        }
        return products;
      } else {
        log("server error in fetchProducts,response-> ${response.body} ${response.statusCode} -> ${response.body}, ${response.statusCode}");
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message: " Something went wrong!,${response.statusCode}");
      }
    } catch (e) {
      log("fetchProducts error: $e");
      rethrow;
    }
  }

  static Future<List<ShopModel1>> fetchShops(LocationInfo? locationInfo) async {
    try {
      // final response = await http.get(Uri.parse(ApiConst.fetchProductUrl));
      final response = await http.post(
        Uri.parse(ApiConst.getProductsByLocation),
        headers: {
          "Content-Type": "application/json",
        },
        body: locationInfo == null ? null : jsonEncode(locationInfo.toJson()),
      );
      if (response.statusCode == 200) {
        final shops = <ShopModel1>[];
        for (var element in jsonDecode(response.body)) {
          shops.add(ShopModel1.fromJson(element));
        }
        log("${shops.length}");
        return shops;
      } else {
        log("error in fetchShops,response-> ${response.body} ${response.statusCode} -> ${response.body}, ${response.statusCode}");
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message: " Something went wrong!,${response.statusCode}");
      }
    } catch (e) {
      log("fetchShops error: $e");
      rethrow;
    }
  }

  static Future<bool?> emailExists(String email) async {
    final response = await http.post(Uri.parse(ApiConst.emailExistsUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email}));
    if (response.statusCode == 200) {
      return bool.fromEnvironment(response.body);
    } else {
      return null;
    }
  }

  static Future<bool?> usernameExists(String username) async {
    final response = await http.post(Uri.parse(ApiConst.usernameExistsUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'username': username}));
    if (response.statusCode == 200) {
      return bool.fromEnvironment(response.body);
    } else {
      return null;
    }
  }

  static Future<List<Product>> fetchMyUploadedProducts(int shopId) async {
    List<Product> products = [];
    try {
      final response = await http.get(
        Uri.parse("${ApiConst.getProductsByShop}?shopId=$shopId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await SecureStorage.getToken()}"
        },
      );
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return products;
        }
        for (var element in jsonDecode(response.body)) {
          // log(element.runtimeType.toString());
          products.add(Product.fromJson(element));
        }
        log("fetchMyUploadedProducts: ${products.length}");
      } else {
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message: "Something went wrong!,${response.statusCode}");
      }
    } catch (e) {
      log("fetchMyUploadedProducts error: $e");
      rethrow;
    }
    return products;
  }

  static Future<List<Order>> fetchMyOrders(int id, Roles role) async {
    List<Order> orders = [];
    try {
      String param = role == Roles.ROLE_CUSTOMER ? "customerId" : "shopId";
      String url = role == Roles.ROLE_CUSTOMER
          ? ApiConst.getOrdersByCustomer
          : ApiConst.getOrdersByShop;
      final response = await http.get(
        Uri.parse("$url?$param=$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await SecureStorage.getToken()}"
        },
      );
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return orders;
        }
        // log("orders body: ${response.body}");
        for (var element in jsonDecode(response.body)) {
          // log(element.runtimeType.toString());
          orders.add(Order.fromMap(element));
          // orders.add(Order.fromMap(element));
        }
      } else {
        log("error in fetchMyOrders,response-> ${response.body} ${response.statusCode} -> ${response.body}, ${response.statusCode}");
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message: "Something went wrong!,${response.statusCode}");
      }
    } catch (e) {
      log("fetchMyOrders error: $e");
      rethrow;
    }
    return orders;
  }

  static Future<void> updateOrderStatus(
      {required String orderId, required String status}) async {
    try {
      final token = await SecureStorage.getToken();
      log(token!);
      final response = await http.post(Uri.parse(ApiConst.updateOrderStatusUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${await SecureStorage.getToken()}"
          },
          body: jsonEncode({'orderId': int.parse(orderId), 'status': status}));
      if (response.statusCode == 200) {
        log(response.body);
      } else {
        log(" error in  updateOrderStatus,response-> ${response.body} ${response.statusCode} -> ${response.body}");
      }
    } catch (e) {
      log("updateOrderStatus error: $e");
      rethrow;
    }
  }

  static Future<List<ShopModel1>> fetchNearbyShops(
      LocationInfo? location) async {
    try {
      List<ShopModel1> shops = [];
      final response = await http.post(Uri.parse(ApiConst.getNearbyShopsUrl),
          headers: {
            "Content-Type": "application/json",
            // "Authorization": "Bearer ${await SecureStorage.getToken()}"
          },
          body: location == null ? null : jsonEncode(location.toJson()));
      if (response.statusCode == 200) {
        for (var element in jsonDecode(response.body)) {
          shops.add(ShopModel1.fromJson(element));
        }
      } else {
        log("serveer error in  fetchNearbyShops,response-> ${response.body} ${response.statusCode} -> ${response.body}");
      }

      return shops;
    } catch (e) {
      log("fetchNearbyShops error: $e");
      rethrow;
    }
  }

  static Future<List<Product>> fetchProductsByShopId(int id) async {
    try {
      List<Product> products = [];
      final response = await http.get(
        Uri.parse("${ApiConst.getProductsByShopId}?shopId=$id"),
        headers: {
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        for (var element in jsonDecode(response.body)) {
          products.add(Product.fromJson(element));
        }
      } else {
        log("serveer error in  fetchProductsByShopId,response-> ${response.body} ${response.statusCode} -> ${response.body}");
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message: "Something went wrong!,${response.statusCode}");
      }
      return products;
    } catch (e) {
      log("fetchShopById error: $e");
      rethrow;
    }
  }

  static Future<List<Product>> fetchProductsByCategoryId(int id) async {
    try {
      List<Product> products = [];
      final response = await http.get(
        Uri.parse("${ApiConst.getProductsByCategoryId}?categoryId=$id"),
        headers: {
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        for (var element in jsonDecode(response.body)) {
          products.add(Product.fromJson(element));
        }
      } else {
        log("serveer error in  fetchProductsByCategoryId,response-> ${response.body} ${response.statusCode} -> ${response.body}");
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message: "Something went wrong!,${response.statusCode}");
      }
      return products;
    } catch (e) {
      log("fetchShopById error: $e");
      rethrow;
    }
  }

  static Future<List<Product>> searchProducts(String searchText) async {
    try {
      List<Product> products = [];
      final response = await http.get(
        Uri.parse("${ApiConst.searchProducts}?query=$searchText"),
        headers: {
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        for (var element in jsonDecode(response.body)) {
          products.add(Product.fromJson(element));
        }
      } else {
        log("serveer error in  searchProducts,response-> ${response.body} ${response.statusCode} -> ${response.body}");
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message: "Something went wrong!,${response.statusCode}");
      }
      return products;
    } catch (e) {
      log("searchProducts error: $e");
      rethrow;
    }
  }
}

enum Roles { ROLE_CUSTOMER, ROLE_SHOP }
