part of 'customer_data_bloc.dart';

abstract class CustomerDataEvent {}

class LoadCustomerDataEvent extends CustomerDataEvent {}

class ChangeCustomerCurrentLocationEvent extends CustomerDataEvent {
  final String? currentLocation;
  ChangeCustomerCurrentLocationEvent({required this.currentLocation});
}

class CustomerDataAddProductToCartEvent extends CustomerDataEvent {
  final Product product;
  CustomerDataAddProductToCartEvent({required this.product});
}

class CustomerDataRemoveProductFromCartEvent extends CustomerDataEvent {
  final Product product;
  CustomerDataRemoveProductFromCartEvent({required this.product});
}

class CustomerDataIncreaseQuantityByOneEvent extends CustomerDataEvent {
  final Product product;
  CustomerDataIncreaseQuantityByOneEvent({required this.product});
}

class CustomerDataDecreaseQuantityByOneEvent extends CustomerDataEvent {
  final Product product;
  CustomerDataDecreaseQuantityByOneEvent({required this.product});
}

class CustomerDataFetchCartItemDetailsEvent extends CustomerDataEvent {
  final List<CartItem> cartItems;
  CustomerDataFetchCartItemDetailsEvent({required this.cartItems});
}

class CustomerDataSearchProductEvent extends CustomerDataEvent {
  final String keyword;

  CustomerDataSearchProductEvent({required this.keyword});
}

/// Reloads the paginated product feed from the first page.
final class CustomerDataLoadProductsEvent extends CustomerDataEvent {}

final class CustomerDataFetchNearbyShopsEvent extends CustomerDataEvent {}

final class CustomerDataFetchCategoriesEvent extends CustomerDataEvent {}

/// Applies a location already resolved by the map picker — no geocoding
/// round trip, unlike [ChangeCustomerCurrentLocationEvent] which takes a
/// free-text place name.
class SetCustomerLocationEvent extends CustomerDataEvent {
  final LocationInfo? location;
  SetCustomerLocationEvent({required this.location});
}

/// Changes how far "nearby" reaches and refetches shops.
class ChangeSearchRadiusEvent extends CustomerDataEvent {
  final double radiusKm;
  ChangeSearchRadiusEvent({required this.radiusKm});
}

class CustomerDataToggleFavouriteEvent extends CustomerDataEvent {
  final Product product;
  CustomerDataToggleFavouriteEvent({required this.product});
}

/// Clears an in-progress search and returns the feed to its default state.
final class CustomerDataClearSearchEvent extends CustomerDataEvent {}
