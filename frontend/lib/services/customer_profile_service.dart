import 'dart:developer';
import 'dart:convert';
import 'dart:ffi';

import 'package:http/http.dart' as http;
import '/constants/rest_api_const.dart';
import '/utils/exceptions/custom_exception.dart';
import '/utils/utils.dart';
import '../data/models/cart.dart';
import '../data/models/product.dart';
import '/utils/exceptions/customer_exception.dart';
import '/utils/secure_storage.dart';

import '../data/models/customer.dart';

class CustomerProfileService {
  // static const String baseApiUrl = 'http://10.0.2.2:8080/customer';

  Future<void> registerCustomer(
      String name, String email, String password) async {
    try {
      final response = await http.post(Uri.parse(ApiConst.customerRegisterUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(
              {'username': name, 'email': email, 'password': password}));
      if (response.statusCode == 400) {
        log(response.body);
        throw CustomerException("Status Code 400: " + response.body);
      }
      if (response.statusCode != 200) {
        log(response.body);
        throw CustomerException(
            'Something went wrong!,Error code: ${response.statusCode}');
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> loginCustomer(String email, String password) async {
    try {
      final response = await http.post(Uri.parse(ApiConst.customerLoginUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({'email': email, 'password': password}));
      if (response.statusCode == 400) {
        log(response.body);
        throw CustomerException(response.body);
      }
      if (response.statusCode != 200) {
        log("${response.statusCode} -> ${response.body}");
        throw CustomerException(
            'Something went wrong! Please check your internet connection.');
      }
      log("token-> ${response.body}");
      await SecureStorage.storeToken(response.body);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<Customer?> isCustomerLoggedIn() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await http.post(
        Uri.parse(ApiConst.customerProfileUrl),
        headers: {"Authorization": "Bearer $token"},
        body: token,
      );
      if (response.statusCode == 200) {
        return Customer.fromJson(response.body);
      } else if (response.statusCode == 401) {
        //token expired or of different role
        await SecureStorage.deleteToken();
        throw CustomerException('Not Valid Credentials');
      } else {
        log("${response.statusCode} -> ${response.body}");
        throw CustomerException(
            'onternal error, ${response.statusCode} -> ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutCustomer() async {
    await SecureStorage.deleteToken();
  }

  static Future<void> updateCartItems(
      {required int customerId, required List<CartItem> cartItems}) async {
    try {
      final response = await http.post(Uri.parse(ApiConst.updateCartUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${await SecureStorage.getToken()}"
          },
          body: jsonEncode({
            'customerId': customerId,
            'cartItems': cartItems.map((e) => e.toMap()).toList()
          }));
      if (response.statusCode == 200) {
        log(response.body);
      } else {
        log(" error in  updateCustomer,response-> ${response.body} ${response.statusCode} -> ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<CartItemDetails>> fetchProductsFromIds(
      List<CartItem> cartItems) async {
    try {
      List<CartItemDetails> cartItemDetails = [];
      final response = await http.post(
          Uri.parse(ApiConst.fetchProductsByIdsUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${await SecureStorage.getToken()}"
          },
          body: jsonEncode(
              {'productIds': cartItems.map((e) => e.productId).toList()}));

      if (response.statusCode == 200) {
        List<Product> products = [];
        final List<dynamic> dynamicList = jsonDecode(response.body);
        for (var i = 0; i < dynamicList.length; i++) {
          products
              .add(Product.fromJson(dynamicList[i] as Map<String, dynamic>));
        }
        for (int i = 0; i < products.length; i++) {
          cartItemDetails.add(CartItemDetails(
            quantity: cartItems[i].quantity,
            product: products[i],
          ));
        }

        return cartItemDetails;
      } else {
        log(" error in  fetchProducts for cart,response-> ${response.body} ${response.statusCode} -> ${response.body}");
        throw cartException;
      }
    } catch (e) {
      log("fetchProductsFromIds error: $e");
      rethrow;
    }
  }
}
