import 'package:flutter/material.dart';

class FormHandler {
  static InputDecoration inputDec(String label) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[200],
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(10.0),
      ),
      labelText: label,
    );
  }

  static String? stringValidator(String? value) {
    if (value == null || value.length < 2) {
      return 'enter a valid field value';
    }
    return null;
  }

  static String? nullCheck(Object? value) {
    if (value == null) {
      return ' field cannot be null';
    }
    return null;
  }
}
