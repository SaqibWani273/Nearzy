part of 'customer_data_bloc.dart';

abstract class CustomerDataState {}

class CustomerDataInitialState extends CustomerDataState {}

class CustomerDataLoadingState extends CustomerDataState {}

class CustomerDataChangingCurrentLocationState extends CustomerDataState {}

class CustomerDataLoadedState extends CustomerDataState {
  bool? isChangingLocation;
  bool? loadingProducts;
  bool? canAddToCart;
  List<Product>? searchProducts;
  List<ShopModel1>? shops;
  bool? loadedCategories;
  CustomerDataLoadedState({
    this.canAddToCart,
    this.isChangingLocation,
    this.loadingProducts,
    this.searchProducts,
    this.shops,
    this.loadedCategories,
  });
}

class CustomerDataErrorState extends CustomerDataState {
  final String error;
  CustomerDataErrorState({required this.error});
}

class CustomerDataFetchingCartItemDetailsState extends CustomerDataState {}

class CustomerDataCartErrorState extends CustomerDataState {
  final CustomException error;

  CustomerDataCartErrorState({required this.error});
}

class CustomerDataCartFetchedCartItemDetailsState extends CustomerDataState {}

class CustomerDataLocationErrorState extends CustomerDataState {
  final CustomException error;
  CustomerDataLocationErrorState({required this.error});
}

class CustomerDataSearchProductState extends CustomerDataState {
  final List<Product> products;

  CustomerDataSearchProductState({required this.products});
}
