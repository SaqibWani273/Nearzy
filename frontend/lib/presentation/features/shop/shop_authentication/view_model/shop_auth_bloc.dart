import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import '/data/models/shop_model/shop_model1.dart';
import '/data/repositories/shop/shop_data_repository.dart';
import '/utils/exceptions/custom_exception.dart';

part 'shop_auth_event.dart';
part 'shop_auth_State.dart';

class ShopAuthBloc extends Bloc<ShopAuthEvent, ShopAuthState> {
  final ShopDataRepository shopDataRepository;

  ShopAuthBloc({required this.shopDataRepository})
      : super(ShopAuthInitialState()) {
    on<ShopAuthLoginEvent>(shopAuthLogin);
    on<ShopAuthRegisterEvent>(shopAuthRegister);
    on<ShopAuthLogoutEvent>(shopAuthLogout);
    on<ShopAuthInitialEvent>(shopAuthInitial);
    on<ShopAuthLoadLocationEvent>(shopAuthLoadLocation);

    // on<LoadAllCategoriesEvent>(_loadAllCategories);
  }
  Future<void> _handleEvent(
      ShopAuthEvent event, Emitter<ShopAuthState> emit) async {
    if (event is ShopAuthLoadLocationEvent) {
      emit(ShopAuthLoadingLocationState());
    } else {
      emit(ShopAuthLoadingState());
    }

    try {
      switch (event) {
        case ShopAuthInitialEvent _:
          await shopDataRepository.loadAllCategories();
          emit(ShopAuthInitialState());
          break;
        case ShopAuthLoginEvent loginEvent:
          await shopDataRepository.loginShop(
              loginEvent.email, loginEvent.password);
          emit(ShopAuthLoggedInState());
          break;
        case ShopAuthRegisterEvent registerEvent:
          await shopDataRepository.registerShop(registerEvent.shopModel);
          emit(ShopAuthEmailSentState());
          break;
        case ShopAuthLogoutEvent _:
          await shopDataRepository.logoutShop();
          emit(ShopAuthLoggedOutState());
          break;
        case ShopAuthLoadLocationEvent loadLocationEvent:
          final String address = await shopDataRepository
              .getLocationAddress(loadLocationEvent.userEnteredLocation);
          emit(ShopAuthLoadedLocationState(address));
          break;
      }
    } on CustomException catch (e) {
      // if (e.errorType == ErrorType.noLocationFound) {
      //   emit(ShopAuthNoLocationFoundState());
      // }
      log("error in ShopAuthBloc: ${e.message}");
      emit(ShopAuthErrorState(e));
    } catch (error) {
      log("error in ShopAuthBloc: $error");
      emit(ShopAuthErrorState(CustomException(
          message: error.toString(), errorType: ErrorType.unknown)));
    }
  }

  void shopAuthInitial(
          ShopAuthInitialEvent event, Emitter<ShopAuthState> emit) =>
      _handleEvent(event, emit);
  void shopAuthLogin(
          ShopAuthLoginEvent loginEvent, Emitter<ShopAuthState> emit) =>
      _handleEvent(loginEvent, emit);

  void shopAuthRegister(
          ShopAuthRegisterEvent registerEvent, Emitter<ShopAuthState> emit) =>
      _handleEvent(registerEvent, emit);

  void shopAuthLogout(ShopAuthLogoutEvent event, Emitter<ShopAuthState> emit) =>
      _handleEvent(event, emit);
  void shopAuthLoadLocation(
          ShopAuthLoadLocationEvent event, Emitter<ShopAuthState> emit) =>
      _handleEvent(event, emit);

// Future<void> _loadAllCategories(
//       LoadAllCategoriesEvent event, Emitter<ShopAuthState> emit) async {
//     await _handleEvent(event, emit);
//   }
}
