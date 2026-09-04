import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nearzy/data/models/shop_model/shop_model1.dart';
import '/utils/exceptions/custom_exception.dart';
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
    on<SetCustomerLocationEvent>(_handleEvent);
    on<ChangeSearchRadiusEvent>(_handleEvent);
    on<CustomerDataToggleFavouriteEvent>(_handleEvent);
    on<CustomerDataClearSearchEvent>(_handleEvent);
  }

  /// Monotonic counter handed to every emitted state so favourite toggles
  /// produce a distinguishable state object.
  int _favouritesRevision = 0;

  /// Builds the next loaded state, carrying forward the fields nothing in
  /// this event touched.
  ///
  /// [shops] and [loadedCategories] describe data the repository is holding,
  /// not the event being handled — but every call site that did not name them
  /// used to reset them to null. So adding one item to the cart emitted a
  /// state claiming no shops and no categories, and the Explore tab fell back
  /// to "no shops nearby" while Browse fell back to its skeleton, both
  /// permanently. That is the "categories sometimes don't load" report.
  ///
  /// Pass a value to change one; omit it to keep what the last state had.
  CustomerDataLoadedState _loaded({
    bool? isChangingLocation,
    bool? loadingProducts,
    bool? canAddToCart,
    List<Product>? searchProducts,
    List<ShopModel1>? shops,
    bool? loadedCategories,
  }) {
    final next = CustomerDataLoadedState(
      isChangingLocation: isChangingLocation,
      loadingProducts: loadingProducts,
      canAddToCart: canAddToCart,
      searchProducts: searchProducts,
      shops: shops ?? _lastLoaded?.shops,
      loadedCategories: loadedCategories ?? _lastLoaded?.loadedCategories,
      favouritesRevision: _favouritesRevision,
    );
    return next;
  }

  /// The last loaded state to leave this bloc, held separately from [state].
  ///
  /// Several handlers emit a non-loaded state on the way — the global loading
  /// state, the cart-details state — so `state` is not a reliable place to
  /// read the previous values from. `LoadCustomerDataEvent`, which the home
  /// feed fires on mount, does exactly that: it emits
  /// `CustomerDataLoadingState` and only then builds its loaded state.
  CustomerDataLoadedState? _lastLoaded;

  /// Recorded here rather than in [_loaded] so it tracks what was actually
  /// emitted, whichever code path produced it.
  @override
  void onChange(Change<CustomerDataState> change) {
    super.onChange(change);
    final next = change.nextState;
    if (next is CustomerDataLoadedState) _lastLoaded = next;
  }

  Future<void> _handleEvent(
    CustomerDataEvent event,
    Emitter<CustomerDataState> emit,
  ) async {
    try {
      if (event is ChangeCustomerCurrentLocationEvent) {
        emit(_loaded(isChangingLocation: true));
      } else if (event is CustomerDataFetchCartItemDetailsEvent) {
        emit(CustomerDataFetchingCartItemDetailsState());
      } else if (event is CustomerDataIncreaseQuantityByOneEvent ||
          event is CustomerDataDecreaseQuantityByOneEvent ||
          event is CustomerDataAddProductToCartEvent ||
          event is CustomerDataRemoveProductFromCartEvent ||
          event is CustomerDataSearchProductEvent ||
          event is CustomerDataToggleFavouriteEvent ||
          event is CustomerDataClearSearchEvent ||
          // Categories are a rail on the feed and a grid on Browse, never the
          // whole screen. Emitting the global loading state for them turned
          // the entire home feed into a skeleton while a decorative strip
          // refreshed.
          event is CustomerDataFetchCategoriesEvent ||
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
          emit(_loaded());

          break;
        case ChangeCustomerCurrentLocationEvent _:
          await customerDataRepository.fetchLocation(event.currentLocation);
          // refresh() re-runs the page-0 fetch through the paging controller,
          // which renders its own first-page progress indicator.
          customerDataRepository.globalPagingController?.refresh();
          emit(_loaded());
          break;
        case CustomerDataLoadProductsEvent _:
          customerDataRepository.globalPagingController?.refresh();
          emit(_loaded());
          break;
        case CustomerDataAddProductToCartEvent _:
          final isAddable = await customerDataRepository.addToCart(
            event.product,
          );
          emit(_loaded(canAddToCart: isAddable));

          break;
        case CustomerDataRemoveProductFromCartEvent _:
          await customerDataRepository.removeFromCart(event.product);
          emit(_loaded());
          break;
        case CustomerDataIncreaseQuantityByOneEvent _:
          await customerDataRepository.increaseQuantityByOne(event.product);
          emit(_loaded());
          break;
        case CustomerDataDecreaseQuantityByOneEvent _:
          await customerDataRepository.decreaseQuantityByOne(event.product);
          emit(_loaded());
          break;
        case CustomerDataFetchCartItemDetailsEvent _:
          await customerDataRepository.fetchMultipleCartItemDetails(
            event.cartItems,
          );
          // emit(CustomerDataCartFetchedCartItemDetailsState());
          emit(_loaded());
          break;
        case CustomerDataSearchProductEvent _:
          emit(_loaded(loadingProducts: true));
          final products = await customerDataRepository.searchProduct(
            event.keyword,
          );
          await customerDataRepository.rememberSearch(event.keyword);
          emit(_loaded(searchProducts: products));
          break;
        case CustomerDataClearSearchEvent _:
          emit(_loaded());
          break;
        case SetCustomerLocationEvent _:
          emit(_loaded(isChangingLocation: true));
          customerDataRepository.setLocation(event.location);
          // The product feed and the shop list are both location-scoped, so
          // both have to be refetched — not just whichever screen is visible.
          customerDataRepository.globalPagingController?.refresh();
          final nearby = await customerDataRepository.fetchNearbyShops();
          emit(_loaded(shops: nearby));
          break;
        case ChangeSearchRadiusEvent _:
          customerDataRepository.radiusKm = event.radiusKm;
          emit(_loaded(isChangingLocation: true));
          final widened = await customerDataRepository.fetchNearbyShops();
          emit(_loaded(shops: widened));
          break;
        case CustomerDataToggleFavouriteEvent _:
          await customerDataRepository.toggleFavourite(event.product);
          _favouritesRevision++;
          emit(_loaded());
          break;
        case CustomerDataFetchNearbyShopsEvent _:
          final shops = await customerDataRepository.fetchNearbyShops();
          emit(_loaded(shops: shops));
          break;
        case CustomerDataFetchCategoriesEvent fetchCategories:
          // Two emits: the first moves the grid onto its skeleton, the second
          // reports whatever the repository settled on. `loadCategories` never
          // throws, so a failure lands here as a `failed` status the grid
          // renders as a retry rather than as the bloc's generic error state.
          emit(_loaded(loadedCategories: false));
          await customerDataRepository.loadCategories(
            force: fetchCategories.force,
          );
          emit(_loaded(loadedCategories: true));
          break;
      }
    } on CustomException catch (e) {
      // Each branch is terminal: emitting the generic error afterwards used
      // to immediately overwrite the specific state the UI keys off.
      if (e.errorType.name.toLowerCase().contains("location")) {
        emit(CustomerDataLocationErrorState(error: e));
      } else if (e.errorType == ErrorType.cartError) {
        emit(CustomerDataCartErrorState(error: e));
      } else {
        emit(CustomerDataErrorState(error: e.message));
      }
    } catch (e) {
      emit(CustomerDataErrorState(error: "unknown error occurred"));
    }
  }

  Future<void> _loadCustomerData(
    LoadCustomerDataEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);

  Future<void> _changeCustomerCurrentLocation(
    ChangeCustomerCurrentLocationEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);
  Future<void> _addToCart(
    CustomerDataAddProductToCartEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);

  Future<void> _removeFromCart(
    CustomerDataRemoveProductFromCartEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);

  Future<void> _increaseQuantityByOne(
    CustomerDataIncreaseQuantityByOneEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);
  Future<void> _decreaseQuantityByOne(
    CustomerDataDecreaseQuantityByOneEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);

  Future<void> _fetchMultipleCartItemDetails(
    CustomerDataFetchCartItemDetailsEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);

  Future<void> _searchProduct(
    CustomerDataSearchProductEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);

  Future<void> _loadProducts(
    CustomerDataLoadProductsEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);
  Future<void> _fetchNearbyShops(
    CustomerDataFetchNearbyShopsEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);
  Future<void> _fetchCategories(
    CustomerDataFetchCategoriesEvent event,
    Emitter<CustomerDataState> emit,
  ) async => await _handleEvent(event, emit);
}
