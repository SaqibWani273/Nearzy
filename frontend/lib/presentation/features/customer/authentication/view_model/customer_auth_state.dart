part of 'customer_auth_bloc.dart';

abstract class CustomerAuthState {}

final class CustomerAuthInitial extends CustomerAuthState {}

final class CustomerAuthLoadingState extends CustomerAuthState {}

final class CustomerAuthRegisteredState extends CustomerAuthState {}

final class CustomerAuthLoggedInState extends CustomerAuthState {}

final class CustomerAuthLoggedOutState extends CustomerAuthState {}

final class CustomerAuthVerifiedState extends CustomerAuthState {}

final class CustomerAuthErrorState extends CustomerAuthState {
  final String message;

  CustomerAuthErrorState(this.message);
}
