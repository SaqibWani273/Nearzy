import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mca_project/data/models/cart.dart';

class OrderItem {
  int productId;
  int quantity;
  int price;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });
  factory OrderItem.fromCartItemDetails(
      {required CartItemDetails cartItemDetails}) {
    return OrderItem(
      productId: cartItemDetails.product.id!,
      quantity: cartItemDetails.quantity,
      price: cartItemDetails.product.price,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'productId': productId,
      'quantity': quantity,
      'price': price * quantity,
    };
  }
}

class PaymentData {
  String buyerName;
  double amount;
  String currency;
  String shippingAddress;
  String billingAddress;
  String phoneNumber;
  List<OrderItem> orderItems;
  int shopId;
  int customerId;

  PaymentData({
    required this.buyerName,
    required this.amount,
    required this.currency,
    required this.shippingAddress,
    required this.billingAddress,
    required this.phoneNumber,
    required this.orderItems,
    required this.shopId,
    required this.customerId,
  });
}

class StripeService {
  static Future<bool> makePayment(PaymentData paymentData) async {
    {
      try {
        var paymentIntent = await createPaymentIntent(paymentData);
        if (paymentIntent == null) return false;
        final result1 = await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          style: ThemeMode.dark,
          merchantDisplayName: "LocalEzy Shop Integration",
          customerEphemeralKeySecret: paymentIntent['ephemeralKey'],
          customerId: paymentIntent['id'],
        ));
        log("result1 --------------->$result1");
        // if (result1 != PaymentSheetPaymentOption) return false;
        final result2 = await displayPaymentSheet(
          () {
            paymentIntent = null;
          },
        );
        if (result2 == false) return false;
        return true;
      } catch (e) {
        log("Error occured in payment: $e");
        return false;
      }
    }
  }

  static Future<Map<String, dynamic>?> createPaymentIntent(
      PaymentData paymentData) async {
    try {
      final secretKey = dotenv.env['STRIPE_SECRET_KEY'];
      Map<String, dynamic> body = {
        'amount': calculateAmount(paymentData.amount).toString(),
        'currency': paymentData.currency.toLowerCase(),
        // 'automatic_payment_methods_enabled': true,

        'description': jsonEncode({
          "shippingAddress": paymentData.shippingAddress,
          "contactNumber": paymentData.phoneNumber,
          "billingAddress": paymentData.billingAddress,
          "orderItems": paymentData.orderItems
              .map(
                (e) => e.toMap(),
              )
              .toList(),
          "customerId": paymentData.customerId,
          "shopId": paymentData.shopId,
          "totalPrice": paymentData.amount,
        }),
        "shipping[name]": "Jenny Rosen",
        "shipping[address][line1]": "510 Townsend St",
        "shipping[address][postal_code]": '98140',
        "shipping[address][city]": "San Francisco",
        "shipping[address][state]": "CA",
        "shipping[address][country]": "IN",

        // 'payment_method_types[]': 'card'
      };
      final response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          headers: {
            'Authorization': 'Bearer $secretKey',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: body);
      if (response.statusCode != 200) return null;
      log("Response: ${jsonDecode(response.body)}");
      // return null;
      return Map<String, dynamic>.from(
          jsonDecode(response.body)); //  jsonDecode(response.body)
    } catch (e) {
      log("Error in creating payment intent: $e");
      return null;
    }
  }

  static Future<bool> displayPaymentSheet(VoidCallback onComplete) async {
    try {
      final paymentSheetResponse = await Stripe.instance.presentPaymentSheet();
      // showDialog(context: context, builder: builder)
      //to do : display payment successfully
      if (paymentSheetResponse != null) {
        log("Payment successfully");
        log("paymentSheetResponse: $paymentSheetResponse");
      }
      onComplete();
      return true;
    } on StripeException catch (e) {
      log("Error in displaying payment sheet: $e");
      return false;
    } catch (e) {
      log("Error in displaying payment sheet: $e");
      return false;
    }
  }

  static int calculateAmount(double amount) {
    final a = (amount * 100).toInt();
    return a;
  }
}
