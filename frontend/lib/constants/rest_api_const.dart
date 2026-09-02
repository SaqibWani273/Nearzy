class ApiConst {
  // static final String baseApiUrl = 'https://clarinet-playlist-wharf.ngrok-free.dev';
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

  // ── Customer Orders ─────────────────────────────────────────────────
  static final String customerOrdersUrl = '$baseCustomerUrl/orders';

  static String customerOrderUrl(int orderId) =>
      '$baseCustomerUrl/orders/$orderId';

  // ── Customer Addresses ──────────────────────────────────────────────
  static final String customerAddressesUrl = '$baseCustomerUrl/addresses';

  static String customerAddressUrl(int addressId) =>
      '$baseCustomerUrl/addresses/$addressId';

  static String customerAddressDefaultUrl(int addressId) =>
      '$baseCustomerUrl/addresses/$addressId/default';

  // ── Customer Payments (Razorpay) ────────────────────────────────────
  static final String paymentConfigUrl = '$baseCustomerUrl/payment/config';
  static final String createPaymentOrderUrl =
      '$baseCustomerUrl/payment/create-order';
  static final String verifyPaymentUrl = '$baseCustomerUrl/payment/verify';

  // ── Customer Location Discovery ─────────────────────────────────────
  static final String shopsNearLocationUrl =
      '$baseCustomerUrl/shops-near-location';
  static final String locationSpecialitiesUrl =
      '$baseCustomerUrl/location-specialities';
  static final String affordableProductsUrl =
      '$baseCustomerUrl/affordable-products';

  // ── Customer Catalogue ──────────────────────────────────────────────
  static final String searchProductsUrl = '$baseCustomerUrl/search-products';
  static final String discountedProductsUrl =
      '$baseCustomerUrl/discounted-products';

  static String shopProductsUrl(int shopId) =>
      '$baseCustomerUrl/shops/$shopId/products';

  static String categoryProductsUrl(int categoryId) =>
      '$baseCustomerUrl/products-by-category/$categoryId';

  // ── Shop Auth ───────────────────────────────────────────────────────
  static final String shopRegistrationUrl = '$baseShopUrl/register';
  static final String shopLoginUrl = '$baseShopUrl/login';
  static final String shopVerifyEmailUrl = '$baseShopUrl/verify-email';

  // ── Shop Orders ─────────────────────────────────────────────────────
  static final String shopOrdersUrl = '$baseShopUrl/orders';

  static String shopOrderStatusUrl(int orderId) =>
      '$baseShopUrl/orders/$orderId/status';

  // ── Shop Profile & Products ─────────────────────────────────────────
  static final String shopProfileUrl = '$baseShopUrl/me';
  static final String uploadProductUrl = '$baseShopUrl/add-product';
  static final String shopMyProductsUrl = '$baseShopUrl/my-products';

  // ── Admin Auth ──────────────────────────────────────────────────────
  static final String adminRegisterUrl = '$baseAdminUrl/register';
  static final String adminLoginUrl = '$baseAdminUrl/login';
  static final String adminVerifyEmailUrl = '$baseAdminUrl/verify-email';
  static final String adminMeUrl = '$baseAdminUrl/me';

  // ── Admin Actions ───────────────────────────────────────────────────
  static final String adminAddCategoryUrl = '$baseAdminUrl/add-category';

  // ── Session ─────────────────────────────────────────────────────────
  /// Exchanges a refresh token for a new access token. The refresh token is
  /// single-use: the response carries its replacement.
  static final String refreshTokenUrl = '$baseUserUrl/refresh';
  static final String logoutUrl = '$baseUserUrl/logout';

  // ── Common ──────────────────────────────────────────────────────────
  static final String loadAllCategoriesUrl = '$baseUserUrl/get-all-categories';
  static final String usernameExistsUrl = '$baseUserUrl/username-exists';
  static final String emailExistsUrl = '$baseUserUrl/email-exists';

  // ── Pagination ──────────────────────────────────────────────────────
  static const int pageSize = 10;
}

class CloudinaryApiConst {
  static String cloudinaryImageUploadUrl =
      'https://api.cloudinary.com/v1_1/dtemdwygc/image/upload';
  static const String cloudinaryApiKey = '727715155817234';
}
