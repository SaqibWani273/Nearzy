part of 'shop_bloc.dart';

abstract class ShopState {}

class ShopInitialState extends ShopState {}

class ShopLoadingState extends ShopState {}

class ShopLoadedAllCategoriesState extends ShopState {}

class ShopUploadedProductState extends ShopState {}

class ShopErrorState extends ShopState {
  final CustomException customException;
  ShopErrorState({required this.customException});
}

class ShopUploadedMultipleImagesState extends ShopState {
  List<String> images;

  ShopUploadedMultipleImagesState({required this.images});
}

class ShopLoadedProductsState extends ShopState {}

class ShopLoadMyOrdersState extends ShopState {}

class ShopSearchProductState extends ShopState {
  final List<Product> products;

  ShopSearchProductState({required this.products});
}

class ShopUpdatedOrderStatusState extends ShopState {}
