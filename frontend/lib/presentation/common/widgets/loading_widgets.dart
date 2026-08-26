import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingWidgets {
  static Widget SpinKitFading(double deviceWidth) => Center(
          child: SpinKitFadingCircle(
        size: deviceWidth * 0.1,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.0),
                color: Colors.blueGrey),
          );
        },
      ));
}
