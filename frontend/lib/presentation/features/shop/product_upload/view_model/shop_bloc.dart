import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import '/data/models/product.dart';

import '../../../../../data/repositories/shop/shop_data_repository.dart';
import '../../../../../utils/exceptions/custom_exception.dart';

part 'shop_event.dart';
part 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final ShopDataRepository shopDataRepository;
  ShopBloc({required this.shopDataRepository}) : super(ShopInitialState()) {
    on<LoadAllCategoriesEvent>(_loadAllCategories);
    on<UploadProductEvent>(_UploadProduct);
    on<ShopInitialEvent>(_shopInitial);
    on<ShopLoadProductsEvent>(_shopLoadProducts);
    on<ShopSearchProductEvent>(_shopSearchProduct);
    on<ShopLoadMyOrdersEvent>(_shopLoadMyOrders);
    on<ShopUpdateOrderStatus>(_shopUpdateOrderStatus);
    // on<UploadMultipleImagesEvent>(_UploadMultipleImages);
  }

  Future<void> _handleEvent(ShopEvent event, Emitter<ShopState> emit) async {
    emit(ShopLoadingState());
    try {
      switch (event) {
        case LoadAllCategoriesEvent _:
          await shopDataRepository.loadAllCategories();
          emit(ShopLoadedAllCategoriesState());
          break;
        case UploadProductEvent uploadProductEvent:
          await shopDataRepository.uploadProduct(
              uploadProductEvent.product, uploadProductEvent.images);
          emit(ShopUploadedProductState());
          break;
        case ShopInitialEvent _:
          emit(ShopInitialState());
          break;
        case ShopLoadProductsEvent _:
          await shopDataRepository.fetchMyUploadedProducts();
          emit(ShopLoadedProductsState());
          break;
        case ShopSearchProductEvent searchProductEvent:
          final List<Product> products =
              shopDataRepository.searchProducts(searchProductEvent.keyword);
          emit(ShopSearchProductState(products: products));
          break;
        case ShopLoadMyOrdersEvent _:
          await shopDataRepository.fetchMyOrders();
          emit(ShopLoadMyOrdersState());
          break;
        case ShopUpdateOrderStatus updateOrderStatus:
          await shopDataRepository.updateOrderStatus(
              updateOrderStatus.orderId, updateOrderStatus.status);
          emit(ShopUpdatedOrderStatusState());
          break;
        // case UploadMultipleImagesEvent uploadMultipleImagesEvent:
        //   final List<String> images = await shopDataRepository
        //       .uploadMultipleImages(uploadMultipleImagesEvent.images);
        //   emit(ShopUploadedMultipleImagesState(images: images));
        //   break;
      }
    } on CustomException catch (e) {
      log("error in ShopBloc: $e");
      emit(ShopErrorState(customException: e));
    } catch (error) {
      log("error in ShopBloc: $error");
      emit(ShopErrorState(
          customException: CustomException(
        message: "Unknown Error",
        errorType: ErrorType.unknown,
      )));
    }
  }

  Future<void> _loadAllCategories(
      LoadAllCategoriesEvent event, Emitter<ShopState> emit) async {
    await _handleEvent(event, emit);
  }

  Future<void> _UploadProduct(
      UploadProductEvent event, Emitter<ShopState> emit) async {
    await _handleEvent(event, emit);
  }

  void _shopInitial(ShopInitialEvent event, Emitter<ShopState> emit) async {
    _handleEvent(event, emit);
  }

  void _shopLoadProducts(ShopLoadProductsEvent event, Emitter<ShopState> emit) =>
      _handleEvent(event, emit);
  void _shopSearchProduct(ShopSearchProductEvent event, Emitter<ShopState> emit) =>
      _handleEvent(event, emit);
  void _shopLoadMyOrders(ShopLoadMyOrdersEvent event, Emitter<ShopState> emit) =>
      _handleEvent(event, emit);
  void _shopUpdateOrderStatus(
          ShopUpdateOrderStatus event, Emitter<ShopState> emit) =>
      _handleEvent(event, emit);

  // Future<void> _UploadMultipleImages(
  //     UploadMultipleImagesEvent event, Emitter<ShopState> emit) async {
  //   await _handleEvent(event, emit);
  // }
}
