class CustomException implements Exception {
  final String message;
  final ErrorType errorType;
  CustomException({required this.message, required this.errorType});
}

enum ErrorType {
  locationpermissionDenied,
  locationServicesDisabled,
  locationPermissionDeniedPermanently,
  noLocationFound,
  internetConnection,
  unknown,
  cartError,
}

final CustomException unknownException = CustomException(
  message: "An internal error occurred.",
  errorType: ErrorType.unknown,
);

final CustomException internetException = CustomException(
  message: "Make sure to have an active internet connection",
  errorType: ErrorType.internetConnection,
);
final CustomException cartException = CustomException(
  message: "Cart Error",
  errorType: ErrorType.cartError,
);
