import 'package:flutter/foundation.dart';

class ApiConst {
  static final String baseApiUrl = 'http://localhost:8080';
  static final String baseCustomerUrl = '$baseApiUrl/customer';
  static final String baseShopUrl = '$baseApiUrl/shop';
  static final String baseAdminUrl = '$baseApiUrl/admin';
  static final String baseUserUrl = '$baseApiUrl/user';

  // ── Customer Auth ───────────────────────────────────────────────────
  static final String customerLoginUrl = '$baseCustomerUrl/login';
  static final String customerRegisterUrl = '$baseCustomerUrl/register';
  static final String customerVerifyEmailUrl = '$baseCustomerUrl/verify-email';

  // ── Customer Profile ────────────────────────────────────────────────
  static final String userProfileUrl = '$baseUserUrl/me';
  static final String customerProfileUrl = '$baseCustomerUrl/me';
  static final String customerUpdateUrl = '$baseCustomerUrl/update';

  // ── Customer Products ───────────────────────────────────────────────
  static final String fetchAllProductsUrl = '$baseCustomerUrl/get-all-products';
  static final String fetchProductsByIdsUrl =
      '$baseCustomerUrl/get-products-by-ids';

  // ── Customer Cart ───────────────────────────────────────────────────
  static final String updateCartUrl = '$baseCustomerUrl/update-cart-items';

  // ── Customer Location Discovery ─────────────────────────────────────
  static final String shopsNearLocationUrl =
      '$baseCustomerUrl/shops-near-location';
  static final String locationSpecialitiesUrl =
      '$baseCustomerUrl/location-specialities';
  static final String affordableProductsUrl =
      '$baseCustomerUrl/affordable-products';

  // ── Shop Auth ───────────────────────────────────────────────────────
  static final String shopRegistrationUrl = '$baseShopUrl/register';
  static final String shopLoginUrl = '$baseShopUrl/login';
  static final String shopVerifyEmailUrl = '$baseShopUrl/verify-email';

  // ── Shop Profile & Products ─────────────────────────────────────────
  static final String shopProfileUrl = '$baseShopUrl/me';
  static final String uploadProductUrl = '$baseShopUrl/add-product';

  // ── Admin Auth ──────────────────────────────────────────────────────
  static final String adminRegisterUrl = '$baseAdminUrl/register';
  static final String adminLoginUrl = '$baseAdminUrl/login';
  static final String adminVerifyEmailUrl = '$baseAdminUrl/verify-email';
  static final String adminMeUrl = '$baseAdminUrl/me';

  // ── Admin Actions ───────────────────────────────────────────────────
  static final String adminAddCategoryUrl = '$baseAdminUrl/add-category';

  // ── Common ──────────────────────────────────────────────────────────
  static final String loadAllCategoriesUrl = '$baseUserUrl/get-all-categories';
  static final String usernameExistsUrl = '$baseUserUrl/username-exists';
  static final String emailExistsUrl = '$baseUserUrl/email-exists';

  // ── Pagination ──────────────────────────────────────────────────────
  static const int pageSize = 10;

  // ── Network ─────────────────────────────────────────────────────────
  static final myIpAddress = '192.168.1.5';
}

class CloudinaryApiConst {
  static String cloudinaryImageUploadUrl =
      'https://api.cloudinary.com/v1_1/dtemdwygc/image/upload';
  static const String cloudinaryApiKey = '727715155817234';
}

String getHostname() {
  if (!kIsWeb) {
    return ApiConst.myIpAddress;
  }
  return 'localhost';
}
