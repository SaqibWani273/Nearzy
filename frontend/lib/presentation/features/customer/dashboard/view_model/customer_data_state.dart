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

  /// True once a category load has settled. It is *not* what the Browse grid
  /// renders from — that reads `CustomerDataRepository.categoriesStatus`,
  /// which distinguishes loading from failed from loaded-and-empty. This flag
  /// exists so the emit carrying that outcome reaches the BlocBuilder, and so
  /// the outcome survives the next unrelated event (see `_loaded`).
  bool? loadedCategories;

  /// Bumped on every favourite toggle so BlocBuilders rebuild — the
  /// favourite set itself lives in the repository, and a state object that
  /// never changes identity would not trigger a rebuild on its own.
  final int favouritesRevision;

  CustomerDataLoadedState({
    this.canAddToCart,
    this.isChangingLocation,
    this.loadingProducts,
    this.searchProducts,
    this.shops,
    this.loadedCategories,
    this.favouritesRevision = 0,
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
