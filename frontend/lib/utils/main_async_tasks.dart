import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '/services/api_service.dart';

import '../data/models/customer.dart';

class NoInternetModel extends UserModel {}

Future<UserModel?> mainAsyncTasks() async {
  // await Future.delayed(const Duration(seconds: 3));
  //check internet
  await dotenv.load(fileName: "assets/.env");
  Stripe.publishableKey = dotenv.env["STRIPE_PUBLISH_KEY"]!;
  await Stripe.instance.applySettings();
  if (await hasInternet()) {
    final userModel = await ApiService.getUserModel();

    return userModel;
  } else {
    return NoInternetModel();
  }
}

// enum UserStatus { loggedInAsCustomer, loggedInAsShop, notLoggedIn, noInternet }

Future<bool> hasInternet() async {
  //check if user has internet connection
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult.contains(ConnectivityResult.mobile) ||
      connectivityResult.contains(ConnectivityResult.wifi) ||
      connectivityResult.contains(ConnectivityResult.ethernet)) {
    return true;
  }

  return false;
}
