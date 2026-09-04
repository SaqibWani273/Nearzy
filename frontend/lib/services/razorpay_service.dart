import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '/constants/rest_api_const.dart';
import '/data/models/cart.dart';
import 'api_client.dart';
import 'session_manager.dart';

/// One line of an order. Carries no price on purpose — the backend prices the
/// order from its own product table so the client cannot dictate what it pays.
class OrderItem {
  final int productId;
  final int quantity;

  OrderItem({required this.productId, required this.quantity});

  factory OrderItem.fromCartItemDetails({
    required CartItemDetails cartItemDetails,
  }) {
    return OrderItem(
      productId: cartItemDetails.product.id!,
      quantity: cartItemDetails.quantity,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'quantity': quantity,
      };
}

class PaymentData {
  final String buyerName;
  final String email;

  /// Id of one of the customer's saved addresses. The backend verifies it
  /// belongs to the caller and stores it on the order — checkout used to send
  /// a free-text string that only ever reached Razorpay's notes, leaving
  /// nothing to deliver against.
  final int addressId;

  final String phoneNumber;
  final List<OrderItem> orderItems;

  PaymentData({
    required this.buyerName,
    required this.email,
    required this.addressId,
    required this.phoneNumber,
    required this.orderItems,
  });
}

enum PaymentStatus { success, cancelled, failed }

class PaymentResult {
  final PaymentStatus status;
  final String? orderNumber;
  final String message;

  const PaymentResult(this.status, this.message, {this.orderNumber});

  bool get isSuccess => status == PaymentStatus.success;
}

/// What the backend hands back for a freshly created order. The key id is the
/// publishable half of the Razorpay credentials; the secret never leaves the
/// server, which is also the only place a payment can be marked as paid.
class _CheckoutOrder {
  final String keyId;
  final String razorpayOrderId;
  final String orderNumber;
  final int amountPaise;
  final String currency;

  _CheckoutOrder.fromMap(Map<String, dynamic> map)
      : keyId = map['keyId'] as String,
        razorpayOrderId = map['razorpayOrderId'] as String,
        orderNumber = map['orderNumber'] as String,
        amountPaise = map['amountPaise'] as int,
        currency = map['currency'] as String;
}

class RazorpayService {
  /// Runs the full checkout: create the order on the backend, let Razorpay
  /// collect the payment, then have the backend verify the signature. An order
  /// only counts as paid once that last step succeeds.
  static Future<PaymentResult> makePayment(PaymentData paymentData) async {
    if (!await SessionManager.instance.hasSession()) {
      return const PaymentResult(
          PaymentStatus.failed, 'Please sign in again to place this order.');
    }

    final _CheckoutOrder order;
    try {
      order = await _createOrder(paymentData);
    } on _CheckoutException catch (e) {
      return PaymentResult(PaymentStatus.failed, e.message);
    }

    final razorpay = Razorpay();
    final completer = Completer<PaymentResult>();

    void complete(PaymentResult result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse response) async {
      complete(await _verifyPayment(order, response));
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      log('Razorpay payment failed: ${response.code} ${response.message}');
      complete(response.code == Razorpay.PAYMENT_CANCELLED
          ? const PaymentResult(PaymentStatus.cancelled, 'Payment cancelled.')
          : PaymentResult(PaymentStatus.failed,
              response.message ?? 'The payment could not be completed.'));
    });

    // Wallets Razorpay hands back to the merchant aren't wired up yet; without
    // this listener the checkout future would never settle.
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      log('Razorpay external wallet selected: ${response.walletName}');
      complete(PaymentResult(PaymentStatus.failed,
          '${response.walletName ?? 'That wallet'} is not supported yet.'));
    });

    razorpay.open({
      'key': order.keyId,
      'order_id': order.razorpayOrderId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'name': 'Nearzy',
      'description': 'Order ${order.orderNumber}',
      'prefill': {
        'name': paymentData.buyerName,
        'email': paymentData.email,
        'contact': paymentData.phoneNumber,
      },
      'theme': {'color': '#1A1B4B'},
    });

    return completer.future.whenComplete(razorpay.clear);
  }

  static Future<_CheckoutOrder> _createOrder(PaymentData paymentData) async {
    late final http.Response response;
    try {
      response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.createPaymentOrderUrl),
        auth: true,
        json: {
          'orderItems': paymentData.orderItems.map((e) => e.toMap()).toList(),
          'addressId': paymentData.addressId,
          'phoneNumber': paymentData.phoneNumber,
        },
      );
    } catch (e) {
      log('Could not reach the order endpoint: $e');
      throw const _CheckoutException('Could not reach Nearzy. Check your connection.');
    }

    if (response.statusCode != 200) {
      throw _CheckoutException(_errorMessage(
          response, 'Your order could not be started. Please try again.'));
    }

    try {
      return _CheckoutOrder.fromMap(
          Map<String, dynamic>.from(jsonDecode(response.body)));
    } catch (e) {
      log('Unexpected create-order payload: ${response.body}');
      throw const _CheckoutException('Nearzy sent back an unexpected response.');
    }
  }

  /// Confirms the payment with the backend.
  ///
  /// The token is resolved here rather than captured at the start of checkout:
  /// a customer can sit on the Razorpay sheet for several minutes, which is
  /// long enough for an access token to lapse — and this is the call that
  /// actually marks the order paid, so it is the worst possible one to lose.
  static Future<PaymentResult> _verifyPayment(
    _CheckoutOrder order,
    PaymentSuccessResponse response,
  ) async {
    try {
      final verification = await NearzyHttp.postJson(
        Uri.parse(ApiConst.verifyPaymentUrl),
        auth: true,
        json: {
          'razorpayOrderId': response.orderId,
          'razorpayPaymentId': response.paymentId,
          'razorpaySignature': response.signature,
        },
      );

      if (verification.statusCode == 200) {
        return PaymentResult(PaymentStatus.success, 'Payment confirmed.',
            orderNumber: order.orderNumber);
      }

      log('Verification rejected: ${verification.statusCode} ${verification.body}');
      return PaymentResult(
        PaymentStatus.failed,
        _errorMessage(verification,
            'We could not confirm your payment. Contact support with order ${order.orderNumber}.'),
        orderNumber: order.orderNumber,
      );
    } catch (e) {
      // The money may well have left the customer's account, so point them at
      // the order number rather than implying nothing happened.
      log('Verification request failed: $e');
      return PaymentResult(
        PaymentStatus.failed,
        'Payment taken but not yet confirmed. Contact support with order ${order.orderNumber}.',
        orderNumber: order.orderNumber,
      );
    }
  }

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Body wasn't JSON — fall through to the generic message.
    }
    return fallback;
  }
}

class _CheckoutException implements Exception {
  final String message;
  const _CheckoutException(this.message);
}
