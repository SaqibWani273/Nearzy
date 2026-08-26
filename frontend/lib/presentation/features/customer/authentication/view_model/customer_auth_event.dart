part of 'customer_auth_bloc.dart';

abstract class CustomerAuthEvent {}

final class CustomerAuthInitialEvent extends CustomerAuthEvent {}

final class CustomerLoginEvent extends CustomerAuthEvent {
  final String email;
  final String password;
  CustomerLoginEvent({required this.email, required this.password});
}

final class CustomerRegisterEvent extends CustomerAuthEvent {
  final String name;
  final String email;
  final String password;
  CustomerRegisterEvent(
      {required this.name, required this.email, required this.password});
}

final class CustomerLogoutEvent extends CustomerAuthEvent {}

final class CustomerAuthVerificationEvent extends CustomerAuthEvent {}

final class CustomerDataLoadMyOrdersEvent extends CustomerAuthEvent {}
