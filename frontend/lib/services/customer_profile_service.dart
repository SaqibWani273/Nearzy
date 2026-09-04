import 'dart:developer';
import 'dart:convert';

import '/constants/bottom_navbar_items.dart';
import '/constants/rest_api_const.dart';
import '/utils/auth_error.dart';
import '/utils/exceptions/custom_exception.dart';
import '../data/models/cart.dart';
import '../data/models/product.dart';
import '/utils/exceptions/customer_exception.dart';
import 'api_client.dart';
import 'session_manager.dart';

import '../data/models/customer.dart';

class CustomerProfileService {
  // static const String baseApiUrl = 'http://10.0.2.2:8080/customer';

  Future<void> registerCustomer(
      String name, String email, String password) async {
    try {
      final response = await NearzyHttp.postJson(
          Uri.parse(ApiConst.customerRegisterUrl),
          json: {'username': name, 'email': email, 'password': password});
      if (response.statusCode != 200) {
        log("registration failed ${response.statusCode} -> ${response.body}");
        throw CustomerException(signUpErrorMessage(
          statusCode: response.statusCode,
          body: response.body,
          role: Roles.ROLE_CUSTOMER,
        ));
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> loginCustomer(String email, String password) async {
    try {
      final response = await NearzyHttp.postJson(
          Uri.parse(ApiConst.customerLoginUrl),
          json: {'email': email, 'password': password});
      if (response.statusCode != 200) {
        // The status line and body go to the log; the person sees one
        // sentence they can act on.
        log("login failed ${response.statusCode} -> ${response.body}");
        throw CustomerException(authErrorMessage(
          statusCode: response.statusCode,
          body: response.body,
          role: Roles.ROLE_CUSTOMER,
        ));
      }
      // Added alongside any account already signed in on this device, so the
      // switcher can move between them without a password.
      await SessionManager.instance.signIn(
        responseBody: response.body,
        fallbackRole: Roles.ROLE_CUSTOMER,
        email: email,
      );
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<Customer?> isCustomerLoggedIn() async {
    try {
      if (!await SessionManager.instance.hasSession()) {
        return null;
      }

      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.customerProfileUrl),
        auth: true,
        json: const {},
      );
      if (response.statusCode == 200) {
        return Customer.fromJson(response.body);
      } else if (response.statusCode == 401) {
        // NearzyHttp already refreshed and retried, so the session is over
        // rather than merely stale.
        await SessionManager.instance.signOutActive();
        throw CustomerException(
            'Your session has ended. Please sign in again.');
      } else {
        log("${response.statusCode} -> ${response.body}");
        throw CustomerException(
            'Nearzy could not load your profile. Please try again.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutCustomer() async {
    await SessionManager.instance.signOutActive();
  }

  static Future<void> updateCartItems(
      {required int customerId, required List<CartItem> cartItems}) async {
    try {
      final response = await NearzyHttp.postJson(
          Uri.parse(ApiConst.updateCartUrl),
          auth: true,
          json: {
            'customerId': customerId,
            'cartItems': cartItems.map((e) => e.toMap()).toList()
          });
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
      final response = await NearzyHttp.postJson(
          Uri.parse(ApiConst.fetchProductsByIdsUrl),
          auth: true,
          json: {'productIds': cartItems.map((e) => e.productId).toList()});

      if (response.statusCode == 200) {
        final List<dynamic> dynamicList = jsonDecode(response.body);
        final Map<int, Product> productsById = {};
        for (final entry in dynamicList) {
          final product = Product.fromJson(entry as Map<String, dynamic>);
          if (product.id != null) productsById[product.id!] = product;
        }

        // Paired by id rather than by position: the server returns the rows in
        // its own order and silently omits ids it no longer has, so walking the
        // two lists in step would attach a line's quantity to another product.
        for (final item in cartItems) {
          final product = productsById[item.productId];
          if (product == null) continue;
          cartItemDetails.add(CartItemDetails(
            quantity: item.quantity,
            product: product,
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
