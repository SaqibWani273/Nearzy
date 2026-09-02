
import 'dart:convert';
import 'dart:developer';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../constants/bottom_navbar_items.dart';
import '../../models/order.dart';
import '/data/models/cart.dart';
import '/data/models/shop_model/shop_model1.dart';
import '/services/api_service.dart';

import '../../../services/customer_profile_service.dart';
import '../../../services/geo_locator_service.dart';
import '../../../utils/secure_storage.dart';
import '../../../utils/utils.dart';
import '../../models/category/product_category/product_category.dart';
import '../../models/customer.dart';
import '/data/models/product.dart';

class CustomerDataRepository {
  List<Product> products = [];
  List<ProductCategory>? categories;
  LocationInfo? currentSelectedLocation = LocationInfo.defaultValue();
  List<ShopModel1>? shops = [];
  List<ProductCategory> productCategories = [];

  /// How far out "nearby" reaches, in km. Surfaced as a radius control on the
  /// Explore screen and echoed as the circle drawn on the map.
  double radiusKm = 15;

  /// Product ids the customer has saved. Held in memory and mirrored to
  /// secure storage so the list survives a restart without needing a
  /// server-side wishlist endpoint.
  final Set<int> favouriteProductIds = <int>{};

  /// Most recent product searches, newest first, capped at [_maxRecent].
  final List<String> recentSearches = <String>[];
  static const int _maxRecent = 8;

  static const String _favouritesKey = 'favourite_product_ids';
  static const String _recentSearchesKey = 'recent_searches';

  Customer? customer;
  List<CartItemDetails> cartItemDetails = [];
  /// Set by the dashboard once it builds its paging controller. Nullable so
  /// that callers refreshing before the dashboard mounts are a no-op instead
  /// of a LateInitializationError.
  PagingController<int, Product>? globalPagingController;
  CustomerDataRepository({
    this.customer,
  });
  // set customer(Customer? customer) => _customer = customer;
  // Customer? get customer => _customer;

  Future<void> registerCustomer(
      String name, String email, String password) async {
    try {
      await CustomerProfileService().registerCustomer(name, email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loginCustomer(String email, String password) async {
    try {
      await CustomerProfileService().loginCustomer(email, password);
      await isCustomerLoggedIn();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> isCustomerLoggedIn() async {
    try {
      customer = await CustomerProfileService().isCustomerLoggedIn();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutCustomer() async {
    await CustomerProfileService().logoutCustomer();
    customer = null;
  }

  /// Fetches a single page of products and returns it.
  ///
  /// infinite_scroll_pagination 5.x drives paging through this return value,
  /// so the controller is no longer mutated from here.
  Future<List<Product>> fetchProducts(int pageKey) async {
    try {
      final newProducts =
          await ApiService.fetchProducts(currentSelectedLocation, pageKey);
      // A refresh restarts at page 0, so drop the previously cached pages
      // instead of appending duplicates to them.
      if (pageKey == 0) {
        products.clear();
      }
      products.addAll(newProducts);
      return newProducts;
    } catch (e) {
      rethrow;
    }
  }

  /// Restores favourites and recent searches from disk. Safe to call more
  /// than once; failures are swallowed because neither is critical enough to
  /// block startup.
  Future<void> restorePreferences() async {
    try {
      final favourites = await SecureStorage.getData(key: _favouritesKey);
      if (favourites != null && favourites.isNotEmpty) {
        favouriteProductIds
          ..clear()
          ..addAll(favourites
              .split(',')
              .map(int.tryParse)
              .whereType<int>());
      }

      final searches = await SecureStorage.getData(key: _recentSearchesKey);
      if (searches != null && searches.isNotEmpty) {
        recentSearches
          ..clear()
          ..addAll(jsonDecode(searches).cast<String>());
      }
    } catch (e) {
      log('restorePreferences failed: $e');
    }
  }

  bool isFavourite(int? productId) =>
      productId != null && favouriteProductIds.contains(productId);

  /// Returns the new state so callers can show the right confirmation.
  Future<bool> toggleFavourite(Product product) async {
    final id = product.id;
    if (id == null) return false;

    final added = favouriteProductIds.contains(id)
        ? (favouriteProductIds.remove(id), false).$2
        : (favouriteProductIds.add(id), true).$2;

    try {
      await SecureStorage.storeData(
        key: _favouritesKey,
        value: favouriteProductIds.join(','),
      );
    } catch (e) {
      log('persisting favourites failed: $e');
    }
    return added;
  }

  Future<void> rememberSearch(String keyword) async {
    final term = keyword.trim();
    if (term.length < 2) return;

    recentSearches
      ..removeWhere((e) => e.toLowerCase() == term.toLowerCase())
      ..insert(0, term);
    if (recentSearches.length > _maxRecent) {
      recentSearches.removeRange(_maxRecent, recentSearches.length);
    }

    try {
      await SecureStorage.storeData(
        key: _recentSearchesKey,
        value: jsonEncode(recentSearches),
      );
    } catch (e) {
      log('persisting recent searches failed: $e');
    }
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    try {
      await SecureStorage.storeData(key: _recentSearchesKey, value: '[]');
    } catch (e) {
      log('clearing recent searches failed: $e');
    }
  }

  /// Applies a location chosen from the map picker. Unlike [fetchLocation]
  /// this needs no geocoding round trip — the picker already resolved it.
  void setLocation(LocationInfo? location) {
    currentSelectedLocation = location;
  }

  Future<void> fetchShops() async {
    try {
      //fetch products
      shops = await ApiService.fetchShops(currentSelectedLocation);
      //fetch categories
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchLocation(String? location) async {
    try {
      if (location == 'global') {
        //user wants to set location to global
        currentSelectedLocation = null;
        return;
      }
      if (location == 'current') //hardcoded string
      {
        //user wants to set location to current
        currentSelectedLocation =
            await GeoLocatorService.fetchLocationInfo(null);
        return;
      }
      currentSelectedLocation =
          await GeoLocatorService.fetchLocationInfo(location);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool?> addToCart(Product product) async {
    try {
      // if(customer!.cartItems!=null && customer!.cartItems!.isNotEmpty&& customer!.cartItems.first.)

      //user adds item to cart without visiting the cart first,in that
      //case we won't have fetched the cart item details yet,so fetch all

      if (cartItemDetails.isEmpty && customer!.cartItems != null) {
        await fetchMultipleCartItemDetails(customer!.cartItems!);
      }
      //if product already exists in cart
      //increase quantity
      if (cartItemDetails.any((element) => element.product.id == product.id)) {
        cartItemDetails
            .firstWhere((element) => element.product.id == product.id)
            .quantity += 1;

        return true;
      }
      //check if new product belongs to same shop
      if (cartItemDetails.isNotEmpty &&
          cartItemDetails.first.product.shop.id != product.shop.id!) {
        return false;
      }
      //now fetch details of only the newly added item
      final x = await CustomerProfileService.fetchProductsFromIds(
          [CartItem(productId: product.id!, quantity: 1)]);
      cartItemDetails.add(x.first);

      //update locally
      customer = customer!.copyWith(
        cartItems: Utils.addToCart(
            product: product, cartItems: customer!.cartItems),
      );
      //update at server
      await CustomerProfileService.updateCartItems(
          customerId: customer!.id!, cartItems: customer!.cartItems!);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFromCart(Product product) async {
    try {
      //update cart locally
      customer = customer!.copyWith(
        cartItems: Utils.removeFromCart(
            product: product, cartItems: customer!.cartItems!),
      );
      cartItemDetails.removeWhere(
        (element) => element.product.id == product.id,
      );
      await CustomerProfileService.updateCartItems(
          customerId: customer!.id!, cartItems: customer!.cartItems!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> increaseQuantityByOne(Product product) async {
    try {
      //update cart locally
      customer = customer!.copyWith(
        cartItems: Utils.increaseQuantityByOne(
            product: product, cartItems: customer!.cartItems!),
      );
      CartItemDetails x = cartItemDetails
          .firstWhere((element) => element.product.id == product.id);
      if (x.quantity == product.stockQuantity) {
        return;
      }

      cartItemDetails
          .firstWhere((element) => element.product.id == product.id)
          .quantity += 1;
      await CustomerProfileService.updateCartItems(
          customerId: customer!.id!, cartItems: customer!.cartItems!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> decreaseQuantityByOne(Product product) async {
    try {
      //update cart locally
      customer = customer!.copyWith(
        cartItems: Utils.decreaseQuantityByOne(
            product: product, cartItems: customer!.cartItems!),
      );
      cartItemDetails
          .firstWhere((element) => element.product.id == product.id)
          .quantity -= 1;

      await CustomerProfileService.updateCartItems(
          customerId: customer!.id!, cartItems: customer!.cartItems!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchMultipleCartItemDetails(List<CartItem> cartItems) async {
    try {
      //here we fetch the products from their ids
      cartItemDetails =
          await CustomerProfileService.fetchProductsFromIds(cartItems);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchMyOrders() async {
    try {
      List<Order> orders =
          await ApiService.fetchMyOrders(customer!.id!, Roles.ROLE_CUSTOMER);
      customer = customer!.copyWith(orders: orders);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> searchProduct(String searchText) async {
    try {
      // Scoped to the browsing area: a hyperlocal marketplace showing results
      // from three states away is worse than showing none.
      return await ApiService.searchProducts(
        searchText,
        location: currentSelectedLocation,
        radiusKm: radiusKm,
      );
    } catch (e) {
      rethrow;
    }

    // List<Product> searchedProducts = [];
    // for (var product in products) {
    //   if (product.name.toLowerCase().contains(searchText.toLowerCase()) ||
    //       product.sku.toLowerCase().contains(searchText.toLowerCase())) {
    //     searchedProducts.add(product);
    //   }
    // }
    // // log("found ${searchedProducts.length} products");
    // return searchedProducts;
  }

  Future<List<ShopModel1>> fetchNearbyShops() async {
    try {
      shops = await ApiService.fetchNearbyShops(
        currentSelectedLocation,
        radiusKm: radiusKm,
      );
      // customer = customer!.copyWith(shops: shops);
      return shops!;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadCategories() async {
    try {
      final response = await ApiService.loadAllCategories(Roles.ROLE_CUSTOMER)
          as List<ProductCategory>?;
      categories = response ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
