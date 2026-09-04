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

  /// A rupee amount. Accepts decimals — a price of ₹285.50 is ordinary, and
  /// the upload form used to accept digits only.
  ///
  /// Paired with [rupeesToPaise] on submit: the wire format is always paise,
  /// so the conversion must happen exactly once, at this boundary.
  static String? rupeeValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter a price';
    final rupees = double.tryParse(text);
    if (rupees == null) return 'Enter a number, e.g. 285.50';
    if (rupees <= 0) return 'Price must be more than zero';
    return null;
  }

  /// A count. Zero is allowed — an out-of-stock item is still worth listing.
  static String? wholeNumberValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter a quantity';
    final count = int.tryParse(text);
    if (count == null) return 'Enter a whole number';
    if (count < 0) return 'Quantity cannot be negative';
    return null;
  }

  /// Rupees as typed by a shopkeeper to the paise the API stores.
  ///
  /// Mirrors what the inventory edit sheet already does. Without it the form's
  /// "285" was sent straight into `priceInPaise` and the product listed at
  /// ₹2.85.
  static int rupeesToPaise(String value) =>
      ((double.tryParse(value.trim()) ?? 0) * 100).round();
}
