import 'package:flutter/cupertino.dart';

TextStyle overfLowTextStyle(
        {required double deviceWidth,
        required double deviceHeight,
        TextStyle? style}) =>
    style == null
        ? TextStyle(
            overflow: TextOverflow.ellipsis,
            fontSize: deviceWidth > 400 ? 18.0 : 12.0)
        : style.copyWith(
            overflow: TextOverflow.ellipsis,
            fontSize: deviceWidth > 400 ? style.fontSize : 12.0);
