part of 'shop_auth_bloc.dart';

abstract class ShopAuthEvent {}

class ShopAuthInitialEvent extends ShopAuthEvent {}

class ShopAuthLoginEvent extends ShopAuthEvent {
  final String email;
  final String password;
  ShopAuthLoginEvent(this.email, this.password);
}

class ShopAuthRegisterEvent extends ShopAuthEvent {
  final ShopModel1 shopModel;

  ShopAuthRegisterEvent(this.shopModel);
}

// final class LoadAllCategoriesEvent extends ShopAuthEvent {}
class ShopAuthLogoutEvent extends ShopAuthEvent {}

class ShopAuthLoadLocationEvent extends ShopAuthEvent {
  final String? userEnteredLocation;
  ShopAuthLoadLocationEvent({this.userEnteredLocation});
}
