part of 'shop_auth_bloc.dart';

abstract class ShopAuthState {}

class ShopAuthInitialState extends ShopAuthState {}

class ShopAuthLoadingState extends ShopAuthState {}

class ShopAuthLoadingLocationState extends ShopAuthState {}

class ShopAuthLoadedLocationState extends ShopAuthState {
  String location;
  ShopAuthLoadedLocationState(this.location);
}

class ShopAuthLoggedInState extends ShopAuthState {}

class ShopAuthLoggedOutState extends ShopAuthState {}

class ShopAuthEmailSentState extends ShopAuthState {}

// class ShopAuthLoadedAllCategoriesState extends ShopAuthState {}

class ShopAuthErrorState extends ShopAuthState {
  // final String message;
  final CustomException error;

  ShopAuthErrorState(this.error);
}
