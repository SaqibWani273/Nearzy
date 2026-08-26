import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../utils/exceptions/custom_exception.dart';
import '../../../utils/get_lottie_image.dart';
import '../../features/shop/shop_authentication/view_model/shop_auth_bloc.dart';

class ErrorScreen extends StatelessWidget {
  final CustomException customException;
  final VoidCallback onTryAgainPressed;
  const ErrorScreen(
      {super.key,
      required this.customException,
      required this.onTryAgainPressed});

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        color:
            Colors.blue.withOpacity(0.4), // const Color(0xFF87CEFA), //sky blue
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: EdgeInsets.symmetric(vertical: 16.0),
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      height: deviceHeight * 0.9,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: getLottieImage(customException)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Text(
                  customException.message,
                  style: const TextStyle(fontSize: 10),
                  //   overflow: TextOverflow.visible,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            if (customException.errorType ==
                ErrorType.locationPermissionDeniedPermanently)
              RichText(
                  textAlign: TextAlign.center,
                  textScaler: const TextScaler.linear(1.5),
                  text: TextSpan(children: [
                    const TextSpan(
                        text: "Go to ", style: TextStyle(color: Colors.white)),
                    TextSpan(
                      text: "app Settings",
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await Geolocator.openAppSettings();
                          if (context.mounted) {
                            context.read<ShopAuthBloc>().add(
                                ShopAuthLoadLocationEvent(
                                    userEnteredLocation: null));
                          }
                        },
                    ),
                    const TextSpan(
                        text: " and enable location permission",
                        style: TextStyle(color: Colors.white)),
                  ])),
            const SizedBox(
              height: 10,
            ),
            TextButton(
                onPressed: onTryAgainPressed,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
                child: const Text(
                  ' Try Again >> ',
                  style: TextStyle(color: Colors.white),
                )),
          ],
        ),
      ),
    );
  }
}
