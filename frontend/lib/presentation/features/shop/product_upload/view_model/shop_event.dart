part of 'shop_bloc.dart';

abstract class ShopEvent {}

final class ShopInitialEvent extends ShopEvent {}

final class LoadAllCategoriesEvent extends ShopEvent {}

final class UploadProductEvent extends ShopEvent {
  final Product product;
  final List<Object> images;

  UploadProductEvent({required this.product, required this.images});
}

final class UploadSingleImageEvent extends ShopEvent {
  final Object image;

  UploadSingleImageEvent({required this.image});
}

final class UploadMultipleImagesEvent extends ShopEvent {
  final List<Object> images;

  UploadMultipleImagesEvent({required this.images});
}

class ShopLoadProductsEvent extends ShopEvent {}

class ShopLoadMyOrdersEvent extends ShopEvent {}

class ShopSearchProductEvent extends ShopEvent {
  final String keyword;

  ShopSearchProductEvent({required this.keyword});
}

class ShopUpdateOrderStatus extends ShopEvent {
  final String orderId;
  final String status;
  ShopUpdateOrderStatus({required this.orderId, required this.status});
}
