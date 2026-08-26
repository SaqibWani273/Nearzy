import 'dart:developer';

import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:mca_project/data/models/Order.dart';
import '/data/models/shop_model/shop_model1.dart';

import '../../../services/geo_locator_service.dart';
import '/services/cloudinary_service.dart';

import '../../../services/api_service.dart';
import '../../../utils/exceptions/custom_exception.dart';
import '../../models/category/category_data.dart';
import '../../models/product.dart';

class ShopDataRepository {
  ShopModel1? shopModel;
  // ShopModel1? shopModel1;
  LocationInfo? locationInfo;
  List<CategoryData> categoriesData = [];
  List<Product> myUploadedProducts = [];
  List<Order> myOrders = [];

  ShopDataRepository({this.shopModel});

  void setShopModel(ShopModel1? shopModel) => this.shopModel = shopModel;

  Future<void> registerShop(ShopModel1 shopModel) async {
    try {
      final newShopModel = shopModel.copyWith(
        ownerIdPicUrl:
            await CloudinaryService.uploadImage(shopModel.ownerIdPicUrl),
        shopPicUrl: await CloudinaryService.uploadImage(shopModel.shopPicUrl),
        pancardPicUrl:
            await CloudinaryService.uploadImage(shopModel.pancardPicUrl),
        ownerPicUrl: await CloudinaryService.uploadImage(shopModel.ownerPicUrl),
      );
      await ApiService.registerShop(newShopModel);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loginShop(String email, String password) async {
    try {
      await ApiService.loginShop(email, password);
      final shModel = await ApiService.getUserModel() as ShopModel1?;
      if (shModel == null) {
        throw CustomException(
            errorType: ErrorType.unknown,
            message: "Error Fetching Shop Data.Please try again!");
      }
      shopModel = shModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutShop() async {
    try {
      await ApiService.logoutShop();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadAllCategories() async {
    try {
      final List<CategoryData>? response =
          await ApiService.loadAllCategories(Roles.ROLE_SHOP)
              as List<CategoryData>?;
      if (response == null) {
        throw CustomException(
            errorType: ErrorType.internetConnection,
            message:
                'Something went wrong! Please check your internet connection.');
      }

      categoriesData = response;
      //need these at shop registration
      // for (CategoryData category in categoriesData) {
      //   productCategories.add(ProductCategory(
      //       description: '',
      //       image: category.image,
      //       name: category.name,
      //       isTopProductCategory: false));
      // }
    } catch (e) {
      log("loadAllCategories error: $e");
      rethrow;
    }
  }

  Future<void> uploadProduct(Product product, List<Object> images) async {
    try {
      final List<String> imagesUrl =
          await CloudinaryService.uploadMultipleImages(images);
      product.setImages = imagesUrl;
      await ApiService.uploadProduct(product);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getLocationAddress(String? userEnteredLocation) async {
    try {
      locationInfo =
          await GeoLocatorService.fetchLocationInfo(userEnteredLocation);
      return locationInfo!.shortAddress;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchMyUploadedProducts() async {
    try {
      myUploadedProducts =
          await ApiService.fetchMyUploadedProducts(shopModel!.id!);
    } catch (e) {
      rethrow;
    }
  }

  List<Product> searchProducts(String searchText) {
    log("searching for $searchText");
    List<Product> searchedProducts = [];
    for (var product in myUploadedProducts) {
      if (product.name.toLowerCase().contains(searchText.toLowerCase()) ||
          product.sku.toLowerCase().contains(searchText.toLowerCase())) {
        searchedProducts.add(product);
      }
    }
    log("found ${searchedProducts.length} products");
    return searchedProducts;
  }

  Future<void> fetchMyOrders() async {
    try {
      myOrders =
          await ApiService.fetchMyOrders(shopModel!.id!, Roles.ROLE_SHOP);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await ApiService.updateOrderStatus(orderId: orderId, status: status);
      Order order = myOrders.firstWhere((x) => x.id == orderId);
      int index = myOrders.indexOf(order);
      order = order.copyWith(status: status);
      myOrders[index] = order;
    } catch (e) {
      rethrow;
    }
  }
}
