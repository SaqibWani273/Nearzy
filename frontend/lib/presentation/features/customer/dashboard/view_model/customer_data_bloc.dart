import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mca_project/data/models/shop_model/shop_model1.dart';
import '/utils/exceptions/custom_exception.dart';
import '/utils/exceptions/customer_exception.dart';
import '../../../../../data/models/cart.dart';
import '../../../../../data/models/product.dart';
import '/data/repositories/customer/customer_data_repository.dart';

part 'customer_data_event.dart';
part 'customer_data_state.dart';

class CustomerDataBloc extends Bloc<CustomerDataEvent, CustomerDataState> {
  final CustomerDataRepository customerDataRepository;
  CustomerDataBloc({required this.customerDataRepository})
      : super(CustomerDataInitialState()) {
    on<LoadCustomerDataEvent>(_loadCustomerData);
    on<ChangeCustomerCurrentLocationEvent>(_changeCustomerCurrentLocation);
    on<CustomerDataAddProductToCartEvent>(_addToCart);
    on<CustomerDataRemoveProductFromCartEvent>(_removeFromCart);
    on<CustomerDataIncreaseQuantityByOneEvent>(_increaseQuantityByOne);
    on<CustomerDataDecreaseQuantityByOneEvent>(_decreaseQuantityByOne);
    on<CustomerDataFetchCartItemDetailsEvent>(_fetchMultipleCartItemDetails);
    on<CustomerDataSearchProductEvent>(_searchProduct);
    on<CustomerDataLoadProductsEvent>(_loadProducts);
    on<CustomerDataFetchNearbyShopsEvent>(_fetchNearbyShops);
    on<CustomerDataFetchCategoriesEvent>(_fetchCategories);
  }
  Future<void> _handleEvent(
      CustomerDataEvent event, Emitter<CustomerDataState> emit) async {
    try {
      if (event is ChangeCustomerCurrentLocationEvent) {
        emit(CustomerDataLoadedState(isChangingLocation: true));
      } else if (event is CustomerDataFetchCartItemDetailsEvent) {
        emit(CustomerDataFetchingCartItemDetailsState());
      } else if (event is CustomerDataIncreaseQuantityByOneEvent ||
          event is CustomerDataDecreaseQuantityByOneEvent ||
          event is CustomerDataAddProductToCartEvent ||
          event is CustomerDataRemoveProductFromCartEvent ||
          event is CustomerDataSearchProductEvent ||
          event is CustomerDataLoadProductsEvent) {
        //do nothing
      } else {
        emit(CustomerDataLoadingState());
      }
      switch (event) {
        case LoadCustomerDataEvent _:
          // await customerDataRepository.fetchLocation('current');
          // // emit(CustomerDataLoadedState(loadingProducts: true));
          // // await customerDataRepository.fetchProducts(0);
          emit(CustomerDataLoadedState());

          break;
        case ChangeCustomerCurrentLocationEvent _:
          await customerDataRepository.fetchLocation(event.currentLocation);
          emit(CustomerDataLoadedState(loadingProducts: true));
          await customerDataRepository.fetchProducts(0);
          customerDataRepository.globalPagingController.refresh();
          emit(CustomerDataLoadedState());
          break;
        case CustomerDataLoadProductsEvent _:
          await customerDataRepository.fetchProducts(event.pageKey);
          emit(CustomerDataLoadedState());
          break;
        case CustomerDataAddProductToCartEvent _:
          final isAddable =
              await customerDataRepository.addToCart(event.product);
          emit(CustomerDataLoadedState(canAddToCart: isAddable));

          break;
        case CustomerDataRemoveProductFromCartEvent _:
          await customerDataRepository.removeFromCart(event.product);
          emit(CustomerDataLoadedState());
          break;
        case CustomerDataIncreaseQuantityByOneEvent _:
          await customerDataRepository.increaseQuantityByOne(event.product);
          emit(CustomerDataLoadedState());
          break;
        case CustomerDataDecreaseQuantityByOneEvent _:
          await customerDataRepository.decreaseQuantityByOne(event.product);
          emit(CustomerDataLoadedState());
          break;
        case CustomerDataFetchCartItemDetailsEvent _:
          await customerDataRepository
              .fetchMultipleCartItemDetails(event.cartItems);
          // emit(CustomerDataCartFetchedCartItemDetailsState());
          emit(CustomerDataLoadedState());
          break;
        case CustomerDataSearchProductEvent _:
          emit(CustomerDataLoadedState(loadingProducts: true));
          final products =
              await customerDataRepository.searchProduct(event.keyword);
          emit(CustomerDataLoadedState(searchProducts: products));
          break;
        case CustomerDataFetchNearbyShopsEvent _:
          final shops = await customerDataRepository.fetchNearbyShops();
          emit(CustomerDataLoadedState(shops: shops));
          break;
        case CustomerDataFetchCategoriesEvent _:
          await customerDataRepository.loadCategories();
          emit(CustomerDataLoadedState(loadedCategories: true));
          break;
      }
    } on CustomException catch (e) {
      if (e.errorType.name.toLowerCase().contains("location")) {
        emit(CustomerDataLocationErrorState(error: e));
      }
      if (e.errorType == ErrorType.cartError) {
        emit(CustomerDataCartErrorState(error: e));
      }

      emit(CustomerDataErrorState(error: e.toString()));
    } catch (e) {
      emit(CustomerDataErrorState(error: "unknown error occurred"));
    }
  }

  Future<void> _loadCustomerData(
          LoadCustomerDataEvent event, Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);

  Future<void> _changeCustomerCurrentLocation(
          ChangeCustomerCurrentLocationEvent event,
          Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);
  Future<void> _addToCart(CustomerDataAddProductToCartEvent event,
          Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);

  Future<void> _removeFromCart(CustomerDataRemoveProductFromCartEvent event,
          Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);

  Future<void> _increaseQuantityByOne(
          CustomerDataIncreaseQuantityByOneEvent event,
          Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);
  Future<void> _decreaseQuantityByOne(
          CustomerDataDecreaseQuantityByOneEvent event,
          Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);

  Future<void> _fetchMultipleCartItemDetails(
          CustomerDataFetchCartItemDetailsEvent event,
          Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);

  Future<void> _searchProduct(CustomerDataSearchProductEvent event,
          Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);

  Future<void> _loadProducts(CustomerDataLoadProductsEvent event,
          Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);
  Future<void> _fetchNearbyShops(CustomerDataFetchNearbyShopsEvent event,
          Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);
  Future<void> _fetchCategories(CustomerDataFetchCategoriesEvent event,
          Emitter<CustomerDataState> emit) async =>
      await _handleEvent(event, emit);
}
