import 'package:lottie/lottie.dart';

import 'exceptions/custom_exception.dart';

LottieBuilder getLottieImage(CustomException customException) {
  late String asset;
  switch (customException.errorType) {
    case ErrorType.locationpermissionDenied:
      asset = 'assets/lottie/no_location.json';
      break;
    case ErrorType.locationServicesDisabled:
      asset = 'assets/lottie/no_location.json';
      break;
    case ErrorType.locationPermissionDeniedPermanently:
      asset = 'assets/lottie/no_location.json';
      break;
    case ErrorType.internetConnection:
      asset = 'assets/lottie/network_error.json';
      break;
    case ErrorType.unknown:
      asset =
          //to do: change lottie file later
          'assets/lottie/unknown.json';
      break;
    default:
      asset =
          //to do: change lottie file later
          'assets/lottie/unknown.json';
  }
  return Lottie.asset(asset, reverse: true);
}
