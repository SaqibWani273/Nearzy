import 'package:flutter_bloc/flutter_bloc.dart';
import '/data/repositories/customer/customer_data_repository.dart';
import '/data/repositories/customer/customer_profile_repository.dart';
import '/utils/exceptions/customer_exception.dart';

part 'customer_auth_event.dart';
part 'customer_auth_state.dart';

class CustomerAuthBloc extends Bloc<CustomerAuthEvent, CustomerAuthState> {
  final CustomerDataRepository customerDataRepository;

  CustomerAuthBloc({required this.customerDataRepository})
      : super(CustomerAuthInitial()) {
    on<CustomerAuthInitialEvent>(customerAuthInitialEvent);
    on<CustomerLoginEvent>(customerLoginEvent);
    on<CustomerRegisterEvent>(customerRegisterEvent);
    on<CustomerLogoutEvent>(customerLogoutEvent);
    on<CustomerAuthVerificationEvent>(customerAuthVerificationEvent);
    on<CustomerDataLoadMyOrdersEvent>(_loadMyOrders);
  }

  Future<void> _handleEvent(
      CustomerAuthEvent event, Emitter<CustomerAuthState> emit) async {
    emit(CustomerAuthLoadingState());
    try {
      switch (event) {
        case CustomerAuthInitialEvent _:
          // await customerProfileRepository.isCustomerLoggedIn();
          emit(CustomerAuthInitial());
          break;
        case CustomerAuthVerificationEvent _:
          await customerDataRepository.isCustomerLoggedIn();
          await customerDataRepository.fetchMyOrders();
          emit(CustomerAuthVerifiedState());
          break;
        case CustomerLoginEvent loginEvent:
          await customerDataRepository.loginCustomer(
              loginEvent.email, loginEvent.password);
          emit(CustomerAuthLoggedInState());
          break;
        case CustomerRegisterEvent registerEvent:
          await customerDataRepository.registerCustomer(
              registerEvent.name, registerEvent.email, registerEvent.password);
          emit(CustomerAuthRegisteredState());
          break;
        case CustomerLogoutEvent _:
          await customerDataRepository.logoutCustomer();
          emit(CustomerAuthLoggedOutState());
          break;
        case CustomerDataLoadMyOrdersEvent _:
          await customerDataRepository.fetchMyOrders();
          emit(CustomerAuthVerifiedState());
          break;
      }
    } on CustomerException catch (e) {
      emit(CustomerAuthErrorState(e.message));
    } catch (error) {
      emit(CustomerAuthErrorState("$error!!! "));
    }
  }

  void customerAuthInitialEvent(
          CustomerAuthInitialEvent event, Emitter<CustomerAuthState> emit) =>
      _handleEvent(event, emit);

  void customerLoginEvent(
          CustomerLoginEvent event, Emitter<CustomerAuthState> emit) =>
      _handleEvent(event, emit);

  void customerRegisterEvent(
          CustomerRegisterEvent event, Emitter<CustomerAuthState> emit) =>
      _handleEvent(event, emit);

  void customerLogoutEvent(
          CustomerLogoutEvent event, Emitter<CustomerAuthState> emit) =>
      _handleEvent(event, emit);

  void customerAuthVerificationEvent(CustomerAuthVerificationEvent event,
          Emitter<CustomerAuthState> emit) =>
      _handleEvent(event, emit);

  Future<void> _loadMyOrders(CustomerDataLoadMyOrdersEvent event,
          Emitter<CustomerAuthState> emit) async =>
      await _handleEvent(event, emit);
}
