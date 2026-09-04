import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer';

import 'package:nearzy/data/models/order.dart';
import 'package:nearzy/data/models/category/product_category/product_category.dart';

import '/data/models/shop_model/shop_api_parser.dart';
import '/data/models/shop_model/shop_model1.dart';
import '/constants/rest_api_const.dart';
import '/utils/auth_error.dart';
import '/utils/exceptions/custom_exception.dart';

import '../constants/bottom_navbar_items.dart';
import '../data/models/category/category_data.dart';
import '../data/models/address.dart';
import '../data/models/listing_draft.dart';
import '../data/models/customer.dart';
import '../data/models/product.dart';
import 'package:http/http.dart' as http;

import '../data/models/auth_session.dart';
import '../data/models/bulk_stock.dart';
import '../data/models/demand_heatmap.dart';
import '../data/models/shop_dashboard.dart';
import '../data/models/shop_product.dart';
import '../data/models/shop_verification.dart';
import 'api_client.dart';
import 'session_manager.dart';

class ApiService {
  /// JSON headers for calls that need no identity. Authenticated calls pass
  /// `auth: true` to [NearzyHttp] instead of building an Authorization header
  /// here — that is what keeps a refreshed token from being missed.
  static const Map<String, String> _json = {'Content-Type': 'application/json'};

  /// The profile of whichever account is currently active.
  ///
  /// Re-read after every account switch, which is what repoints the app shell
  /// at the right home screen.
  static Future<UserModel?> getUserModel() async {
    try {
      if (!await SessionManager.instance.hasSession()) {
        return null;
      }

      // `/user/me` only authorizes customers and shops, so asking it for an
      // admin earns a 403 ROLE_MISMATCH on every start and every account
      // switch. Admins have no profile model to fetch — main.dart routes them
      // off the session's own role — so skip the round-trip entirely.
      if (SessionManager.instance.active?.role == Roles.ROLE_ADMIN) {
        return null;
      }

      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.userProfileUrl),
        auth: true,
        json: const {},
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final decodedResponse = jsonDecode(response.body);
          final model = decodedResponse['model'];
          if (model is! Map<String, dynamic>) {
            log("Profile response carried no model --> ${response.body}");
            return null;
          }
          final role = rolesFromWire(decodedResponse['role'] as String?);
          if (role == Roles.ROLE_CUSTOMER) {
            return Customer.fromMap(model);
          } else if (role == Roles.ROLE_SHOP) {
            // Tolerant parser, not ShopModel1.fromJson: its generated casts
            // are non-nullable, so a server still answering with a raw ORM
            // row (no `user.password`, category objects, `longitude`) threw
            // on the first cast and dropped the shop straight back to login.
            return ShopApiParser.parse(model);
          }
        }
        log("Server did not return any data--> ${response.body}");
        return null;
      } else if (response.statusCode == 401) {
        // The retry inside NearzyHttp already tried a refresh, so a 401 here
        // means the session is genuinely over.
        await SessionManager.instance.signOutActive();
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
      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.shopRegistrationUrl),
        json: shopModel.toJson(),
      );
      if (response.statusCode == 200) {
        log(response.body);
      } else {
        log('shop registration failed ${response.statusCode} -> ${response.body}');
        throw CustomException(
          errorType: ErrorType.unknown,
          message: signUpErrorMessage(
            statusCode: response.statusCode,
            body: response.body,
            role: Roles.ROLE_SHOP,
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> loginShop(String email, String password) async {
    try {
      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.shopLoginUrl),
        json: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        // Recorded as an account rather than a lone token, so signing in as a
        // shop from the customer app adds a second identity instead of
        // replacing the first.
        await SessionManager.instance.signIn(
          responseBody: response.body,
          fallbackRole: Roles.ROLE_SHOP,
          email: email,
        );
      } else {
        log('shop login failed ${response.statusCode} -> ${response.body}');
        throw CustomException(
          errorType: response.statusCode >= 500
              ? ErrorType.internetConnection
              : ErrorType.unknown,
          message: authErrorMessage(
            statusCode: response.statusCode,
            body: response.body,
            role: Roles.ROLE_SHOP,
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logoutShop() async {
    try {
      await SessionManager.instance.signOutActive();
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>?> loadAllCategories(Roles role) async {
    try {
      final response = await NearzyHttp.get(
        Uri.parse(ApiConst.loadAllCategoriesUrl),
        headers: _json,
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
        log('loading categories failed ${response.statusCode} -> ${response.body}');
        throw CustomException(
          errorType: ErrorType.internetConnection,
          message: 'Could not load categories. Check your connection and '
              'try again.',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> uploadProduct(Product product) async {
    try {
      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.uploadProductUrl),
        auth: true,
        json: product.toCreateJson(),
      );
      if (response.statusCode != 200) {
        final String errorMessage = jsonDecode(
          response.body,
        )["message"].toString();
        throw CustomException(
          errorType: ErrorType.internetConnection,
          message:
              "Server Error ->  ${response.statusCode} -> ${errorMessage.length > 40 ? errorMessage.substring(0, 40) : errorMessage}",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reads a product photo and returns fields for the owner to confirm.
  ///
  /// Sends the image inline rather than uploading it first: the photo is on the
  /// device and not yet in Cloudinary at this point in the flow, and uploading
  /// every picked image would leave orphans behind for products the owner never
  /// finishes. Compressed with the same helper the Cloudinary path uses, so a
  /// phone photo doesn't become a multi-megabyte JSON body.
  static Future<ListingDraft> draftProductFromImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.draftProductUrl),
        auth: true,
        json: {'imageBase64': base64Encode(imageBytes), 'mimeType': mimeType},
      );
      if (response.statusCode != 200) {
        // The manual form still works, so this is a degraded feature rather
        // than a failed upload. The server's own wording is written for API
        // clients — "Set GEMINI_API_KEY" is not something to show a
        // shopkeeper — so translate by code and keep the raw message for the
        // log only.
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        log('draftProductFromImage ${response.statusCode}: ${body['message']}');
        throw CustomException(
          errorType: ErrorType.unknown,
          message: switch (body['code']) {
            'DRAFT_TIMEOUT' => 'That took too long.',
            'DRAFT_UNAVAILABLE' => "Photo reading isn't switched on.",
            _ => "Couldn't read that photo.",
          },
        );
      }
      return ListingDraft.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Product>> fetchProducts(
    LocationInfo? locationInfo,
    int currentPageKey,
  ) async {
    try {
      final response = await NearzyHttp.get(
        Uri.parse(
          "${ApiConst.fetchAllProductsUrl}?page=$currentPageKey&pageSize=${ApiConst.pageSize}",
        ),
        headers: _json,
      );
      if (response.statusCode == 200) {
        final products = <Product>[];
        for (var element in jsonDecode(response.body)) {
          products.add(Product.fromJson(element));
        }
        return products;
      } else {
        log(
          "server error in fetchProducts,response-> ${response.body} ${response.statusCode}",
        );
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
      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.emailExistsUrl),
        json: {'email': email},
      );
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
      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.usernameExistsUrl),
        json: {'username': username},
      );
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
  }) => _fetchProductPage(
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

  // ── Orders ────────────────────────────────────────────────────────────

  /// Fails fast when nobody is signed in.
  ///
  /// Order and address endpoints are all authenticated, and a silent empty
  /// list would be indistinguishable from "you have no orders" — which is
  /// exactly how the old stub hid the fact that no endpoint existed. The
  /// token itself is attached by [NearzyHttp], which also renews it.
  static Future<void> _requireSession() async {
    if (!await SessionManager.instance.hasSession()) {
      throw CustomException(
        errorType: ErrorType.unknown,
        message: 'Please sign in again.',
      );
    }
  }

  /// Surfaces the backend's own `message` when it sends one.
  static Never _throwFor(http.Response response, String fallback) {
    String message = fallback;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } catch (_) {
      // Body was not JSON — keep the fallback.
    }
    throw CustomException(
      errorType: response.statusCode >= 500
          ? ErrorType.internetConnection
          : ErrorType.unknown,
      message: message,
    );
  }

  /// The signed-in customer's order history, newest first.
  static Future<List<Order>> fetchCustomerOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final uri = Uri.parse(ApiConst.customerOrdersUrl).replace(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    await _requireSession();
    final response = await NearzyHttp.get(uri, auth: true, headers: _json);
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load your orders.');
    }
    return _unwrap(
      jsonDecode(response.body),
      'orders',
    ).whereType<Map<String, dynamic>>().map(Order.fromJson).toList();
  }

  /// One order in full. Used by the detail screen so it always shows current
  /// status rather than whatever the list was holding.
  static Future<Order> fetchCustomerOrder(int orderId) async {
    await _requireSession();
    final response = await NearzyHttp.get(
      Uri.parse(ApiConst.customerOrderUrl(orderId)),
      auth: true,
      headers: _json,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load that order.');
    }
    return Order.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  /// Orders containing this shop's items. The server resolves the shop from
  /// the bearer token and narrows each order to that shop's own lines.
  static Future<List<Order>> fetchShopOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final uri = Uri.parse(ApiConst.shopOrdersUrl).replace(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    await _requireSession();
    final response = await NearzyHttp.get(uri, auth: true, headers: _json);
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load your orders.');
    }
    return _unwrap(
      jsonDecode(response.body),
      'orders',
    ).whereType<Map<String, dynamic>>().map(Order.fromJson).toList();
  }

  /// Advances one order. The backend accepts only the immediate next step
  /// (or a cancellation) and answers 400 otherwise, so its message is worth
  /// surfacing rather than swallowing.
  static Future<Order> updateOrderStatus({
    required int orderId,
    required OrderStatus status,
  }) async {
    await _requireSession();
    final response = await NearzyHttp.patch(
      Uri.parse(ApiConst.shopOrderStatusUrl(orderId)),
      auth: true,
      headers: _json,
      body: jsonEncode({'status': status.wire}),
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not update that order.');
    }
    return Order.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  // ── Delivery addresses ────────────────────────────────────────────────

  static Future<List<Address>> fetchAddresses() async {
    await _requireSession();
    final response = await NearzyHttp.get(
      Uri.parse(ApiConst.customerAddressesUrl),
      auth: true,
      headers: _json,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load your addresses.');
    }
    return _unwrap(
      jsonDecode(response.body),
      'addresses',
    ).whereType<Map<String, dynamic>>().map(Address.fromJson).toList();
  }

  static Future<Address> createAddress(
    Address address, {
    bool? asDefault,
  }) async {
    await _requireSession();
    final response = await NearzyHttp.post(
      Uri.parse(ApiConst.customerAddressesUrl),
      auth: true,
      headers: _json,
      body: jsonEncode(address.toRequestBody(asDefault: asDefault)),
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not save that address.');
    }
    return Address.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  static Future<Address> updateAddress(
    Address address, {
    bool? asDefault,
  }) async {
    final id = address.id;
    if (id == null) {
      throw CustomException(
        errorType: ErrorType.unknown,
        message: 'That address has not been saved yet.',
      );
    }
    await _requireSession();
    final response = await NearzyHttp.put(
      Uri.parse(ApiConst.customerAddressUrl(id)),
      auth: true,
      headers: _json,
      body: jsonEncode(address.toRequestBody(asDefault: asDefault)),
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not update that address.');
    }
    return Address.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  static Future<Address> setDefaultAddress(int addressId) async {
    await _requireSession();
    final response = await NearzyHttp.patch(
      Uri.parse(ApiConst.customerAddressDefaultUrl(addressId)),
      auth: true,
      headers: _json,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not change your default address.');
    }
    return Address.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  /// The backend answers 409 for an address referenced by a past order, so
  /// order history never ends up pointing at a deleted row.
  static Future<void> deleteAddress(int addressId) async {
    await _requireSession();
    final response = await NearzyHttp.delete(
      Uri.parse(ApiConst.customerAddressUrl(addressId)),
      auth: true,
      headers: _json,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not remove that address.');
    }
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
      final response = await NearzyHttp.get(
        Uri.parse(
          ApiConst.shopsNearLocationUrl,
        ).replace(queryParameters: query),
        headers: _json,
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
      shops.sort(
        (a, b) => (a.distanceKm ?? double.infinity).compareTo(
          b.distanceKm ?? double.infinity,
        ),
      );
      return shops;
    } catch (e) {
      log("fetchNearbyShops error: $e");
      return [];
    }
  }

  static Future<List<Product>> fetchLocationSpecialities(
    LocationInfo? location,
  ) async {
    try {
      final response = await NearzyHttp.get(
        Uri.parse(
          ApiConst.locationSpecialitiesUrl,
        ).replace(queryParameters: _locationQuery(location)),
        headers: _json,
      );
      if (response.statusCode != 200) {
        log("fetchLocationSpecialities -> ${response.statusCode}");
        return [];
      }
      return _unwrap(
        jsonDecode(response.body),
        'products',
      ).whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
    } catch (e) {
      log("fetchLocationSpecialities error: $e");
      return [];
    }
  }

  /// Cheapest-first available products from shops nearby, optionally capped
  /// at [maxPriceInPaise] — which is what the dashboard's budget chips drive.
  static Future<List<Product>> fetchAffordableProducts(
    LocationInfo? location, {
    double radiusKm = 15,
    int? maxPriceInPaise,
    int page = 1,
    int limit = 20,
  }) => _fetchProductPage(
    Uri.parse(ApiConst.affordableProductsUrl).replace(
      queryParameters: {
        ..._locationQuery(location, radiusKm: radiusKm),
        if (maxPriceInPaise != null) 'maxPriceInPaise': '$maxPriceInPaise',
        'page': '$page',
        'limit': '$limit',
      },
    ),
    label: 'fetchAffordableProducts',
  );

  /// Shared fetch for the paginated product endpoints, all of which answer
  /// with a `{total, page, products}` envelope.
  static Future<List<Product>> _fetchProductPage(
    Uri uri, {
    required String label,
    bool authorized = false,
  }) async {
    try {
      final response = await NearzyHttp.get(
        uri,
        auth: authorized,
        headers: _json,
      );
      if (response.statusCode != 200) {
        log("$label -> ${response.statusCode} ${response.body}");
        return [];
      }

      return _unwrap(
        jsonDecode(response.body),
        'products',
      ).whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
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
  }) => _fetchProductPage(
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
  }) => _fetchProductPage(
    Uri.parse(
      ApiConst.shopProductsUrl(id),
    ).replace(queryParameters: {'page': '$page', 'limit': '$limit'}),
    label: 'fetchProductsByShopId',
  );

  static Future<List<Product>> fetchProductsByCategoryId(
    int id, {
    LocationInfo? location,
    double radiusKm = 15,
    int page = 1,
    int limit = 40,
  }) => _fetchProductPage(
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
    final response = await NearzyHttp.postJson(
      Uri.parse(ApiConst.adminLoginUrl),
      json: {'email': email, 'password': password},
    );
    if (response.statusCode == 200) {
      await SessionManager.instance.signIn(
        responseBody: response.body,
        fallbackRole: Roles.ROLE_ADMIN,
        email: email,
      );
    } else {
      log('admin login failed ${response.statusCode} -> ${response.body}');
      throw CustomException(
        errorType: response.statusCode >= 500
            ? ErrorType.internetConnection
            : ErrorType.unknown,
        message: authErrorMessage(
          statusCode: response.statusCode,
          body: response.body,
          role: Roles.ROLE_ADMIN,
        ),
      );
    }
  }

  static Future<void> adminAddCategory({
    required String name,
    required String description,
    required String image,
    required bool isTopProductCategory,
  }) async {
    final response = await NearzyHttp.postJson(
      Uri.parse(ApiConst.adminAddCategoryUrl),
      auth: true,
      json: {
        'name': name,
        'description': description,
        'image': image,
        'isTopProductCategory': isTopProductCategory,
      },
    );
    if (response.statusCode != 200) {
      throw CustomException(
        errorType: ErrorType.unknown,
        message: 'Failed to add category',
      );
    }
  }

  // ── Shop dashboard & alerts ───────────────────────────────────────────

  /// The shop's triage payload: orders awaiting dispatch, open alerts,
  /// inventory counts. The shop is resolved from the bearer token.
  static Future<ShopDashboard> fetchShopDashboard() async {
    await _requireSession();
    final response = await NearzyHttp.get(
      Uri.parse(ApiConst.shopDashboardUrl),
      auth: true,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load your dashboard.');
    }
    return ShopDashboard.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Open alerts by default; pass `status: 'ALL'` for the full history.
  static Future<List<ShopAlert>> fetchShopAlerts({String? status}) async {
    await _requireSession();
    final response = await NearzyHttp.get(
      Uri.parse(
        ApiConst.shopAlertsUrl,
      ).replace(queryParameters: {'status': ?status}),
      auth: true,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load your alerts.');
    }
    return _unwrap(
      jsonDecode(response.body),
      'alerts',
    ).map((e) => ShopAlert.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Marks an alert READ or RESOLVED.
  static Future<void> setAlertStatus(int alertId, String status) async {
    await _requireSession();
    final response = await NearzyHttp.patch(
      Uri.parse(ApiConst.shopAlertUrl(alertId)),
      auth: true,
      headers: _json,
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not update that alert.');
    }
  }

  // ── Shop inventory writes ─────────────────────────────────────────────

  /// The shop's own inventory in the owner's view — including hidden items and
  /// the markdown fields the customer feed does not carry.
  ///
  /// Distinct from [fetchMyUploadedProducts], which returns the customer-facing
  /// [Product] shape that the older upload flow still parses.
  static Future<List<ShopProduct>> fetchMyShopProducts({
    String? query,
    int page = 1,
    int limit = 100,
  }) async {
    await _requireSession();
    final response = await NearzyHttp.get(
      Uri.parse(ApiConst.shopMyProductsUrl).replace(
        queryParameters: {
          if (query != null && query.trim().length >= 2) 'q': query.trim(),
          'page': '$page',
          'limit': '$limit',
        },
      ),
      auth: true,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load your inventory.');
    }
    return _unwrap(
      jsonDecode(response.body),
      'products',
    ).map((e) => ShopProduct.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// One product from the signed-in shop's own inventory, including items it
  /// has hidden. Callers that hold only an id — a low-stock alert, a scanned
  /// barcode — start here.
  static Future<ShopProduct> fetchMyProduct(int productId) async {
    await _requireSession();
    final response = await NearzyHttp.get(
      Uri.parse(ApiConst.shopProductUrl(productId)),
      auth: true,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load that product.');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return ShopProduct.fromJson(decoded['product'] as Map<String, dynamic>);
  }

  /// Updates price, stock, availability or markdown settings on one product.
  ///
  /// Only the fields passed are sent, so a sheet that edits stock alone cannot
  /// accidentally reset a discount to its default.
  static Future<ShopProduct> updateProduct(
    int productId, {
    int? priceInPaise,
    double? discountPercent,
    int? stockQuantity,
    bool? available,
    bool? markdownEnabled,
    double? markdownFloorPercent,
  }) async {
    await _requireSession();
    final response = await NearzyHttp.patch(
      Uri.parse(ApiConst.shopProductUrl(productId)),
      auth: true,
      headers: _json,
      body: jsonEncode({
        'priceInPaise': ?priceInPaise,
        'discountPercent': ?discountPercent,
        'stockQuantity': ?stockQuantity,
        'available': ?available,
        'markdownEnabled': ?markdownEnabled,
        'markdownFloorPercent': ?markdownFloorPercent,
      }),
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not update that product.');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return ShopProduct.fromJson(decoded['product'] as Map<String, dynamic>);
  }

  /// Applies a batch of scanned stock adjustments. Unknown SKUs come back in
  /// the result rather than failing the batch.
  static Future<BulkStockResult> bulkAdjustStock(
    List<BulkStockEntry> entries,
  ) async {
    await _requireSession();
    final response = await NearzyHttp.postJson(
      Uri.parse(ApiConst.shopBulkStockUrl),
      auth: true,
      json: {'entries': entries.map((e) => e.toJson()).toList()},
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not apply those stock changes.');
    }
    return BulkStockResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // ── Admin ─────────────────────────────────────────────────────────────

  /// Platform counters for the admin overview.
  static Future<Map<String, int>> fetchAdminStats() async {
    await _requireSession();
    final response = await NearzyHttp.get(
      Uri.parse(ApiConst.adminStatsUrl),
      auth: true,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load platform stats.');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
  }

  /// The shop verification queue, oldest submission first.
  static Future<List<ShopVerification>> fetchShopVerifications({
    String status = 'PENDING',
    int page = 1,
    int limit = 20,
  }) async {
    await _requireSession();
    final response = await NearzyHttp.get(
      Uri.parse(ApiConst.adminShopVerificationsUrl).replace(
        queryParameters: {'status': status, 'page': '$page', 'limit': '$limit'},
      ),
      auth: true,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load the verification queue.');
    }
    return _unwrap(
      jsonDecode(response.body),
      'verifications',
    ).map((e) => ShopVerification.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Approves or rejects one application. `status` is APPROVED or REJECTED.
  static Future<void> decideShopVerification(int shopId, String status) async {
    await _requireSession();
    final response = await NearzyHttp.postJson(
      Uri.parse(ApiConst.adminVerificationDecideUrl(shopId)),
      auth: true,
      json: {'status': status},
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not record that decision.');
    }
  }

  /// Weighted order-density points for the admin demand map.
  static Future<DemandHeatmap> fetchDemandHeatmap({int days = 30}) async {
    await _requireSession();
    final response = await NearzyHttp.get(
      Uri.parse(
        ApiConst.adminDemandHeatmapUrl,
      ).replace(queryParameters: {'days': '$days'}),
      auth: true,
    );
    if (response.statusCode != 200) {
      _throwFor(response, 'Could not load demand data.');
    }
    return DemandHeatmap.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
