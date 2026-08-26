import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../constants/rest_api_const.dart';
import '../../models/Order.dart';
import '/data/models/cart.dart';
import '/data/models/shop_model/shop_model1.dart';
import '/services/api_service.dart';

import '../../../services/customer_profile_service.dart';
import '../../../services/geo_locator_service.dart';
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

  Customer? customer;
  List<CartItemDetails> cartItemDetails = [];
  late PagingController<int, Product> globalPagingController;
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

  Future<void> fetchProducts(
    int pageKey,

    //  PagingController pagingController
  ) async {
    try {
      //fetch products
      final newProducts =
          await ApiService.fetchProducts(currentSelectedLocation, pageKey);
      products.addAll(newProducts);
      final isLastPage = newProducts.length < ApiConst.pageSize;
      if (isLastPage) {
        globalPagingController.appendLastPage(newProducts);
      } else {
        final nextPageKey = pageKey + 1;
        // final nextPageKey = pageKey + newProducts.length;
        globalPagingController.appendPage(newProducts, nextPageKey);
      }
      //fetch categories
    } catch (e) {
      rethrow;
    }
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
        cartItems: await Utils.addToCart(
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
        cartItems: await Utils.removeFromCart(
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
        cartItems: await Utils.increaseQuantityByOne(
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
        cartItems: await Utils.decreaseQuantityByOne(
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
      return await ApiService.searchProducts(searchText);
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
      shops = await ApiService.fetchNearbyShops(currentSelectedLocation);
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
