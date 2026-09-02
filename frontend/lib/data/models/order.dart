import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'address.dart';

/// An order, as returned by `GET /customer/orders` and `GET /shop/orders`.
///
/// Rewritten against the real `orderDto` payload. The previous version parsed
/// a Java-era shape (`orderDetails.customer.myUser.username`) that the Node
/// backend never produced, and its status enum used values — PENDING,
/// PROCESSING — that do not exist in OrderRecord, so order filtering could
/// never have matched.
///
/// One model serves both roles: the shop view additionally carries [customer]
/// and is already narrowed server-side to that shop's own line items.

/// Wire values are the uppercase strings the backend stores, kept separate
/// from the Dart names so parsing does not depend on `enum.name`.
enum OrderStatus {
  placed('PLACED', 'Placed'),
  confirmed('CONFIRMED', 'Confirmed'),
  shipped('SHIPPED', 'Shipped'),
  delivered('DELIVERED', 'Delivered'),
  cancelled('CANCELLED', 'Cancelled');

  const OrderStatus(this.wire, this.label);

  final String wire;
  final String label;

  static OrderStatus fromWire(String? value) => OrderStatus.values.firstWhere(
        (s) => s.wire == (value ?? '').toUpperCase(),
        orElse: () => OrderStatus.placed,
      );

  /// Mirrors the backend's forward-only lifecycle. Null once terminal, which
  /// is what hides the shop's "advance" control.
  OrderStatus? get next => switch (this) {
        OrderStatus.placed => OrderStatus.confirmed,
        OrderStatus.confirmed => OrderStatus.shipped,
        OrderStatus.shipped => OrderStatus.delivered,
        OrderStatus.delivered => null,
        OrderStatus.cancelled => null,
      };

  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  /// Semantic colours only — an order status is not a brand accent.
  Color get color => switch (this) {
        OrderStatus.placed => AppColors.info,
        OrderStatus.confirmed => AppColors.info,
        OrderStatus.shipped => AppColors.warning,
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.error,
      };

  Color get surface => switch (this) {
        OrderStatus.placed => AppColors.infoSurface,
        OrderStatus.confirmed => AppColors.infoSurface,
        OrderStatus.shipped => AppColors.warningSurface,
        OrderStatus.delivered => AppColors.successSurface,
        OrderStatus.cancelled => AppColors.errorSurface,
      };

  IconData get icon => switch (this) {
        OrderStatus.placed => Icons.receipt_long_outlined,
        OrderStatus.confirmed => Icons.check_circle_outline_rounded,
        OrderStatus.shipped => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.inventory_2_outlined,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };
}

enum PaymentStatus {
  pending('PENDING', 'Payment pending'),
  paid('PAID', 'Paid'),
  failed('FAILED', 'Payment failed'),
  refunded('REFUNDED', 'Refunded');

  const PaymentStatus(this.wire, this.label);

  final String wire;
  final String label;

  static PaymentStatus fromWire(String? value) =>
      PaymentStatus.values.firstWhere(
        (s) => s.wire == (value ?? '').toUpperCase(),
        orElse: () => PaymentStatus.pending,
      );

  bool get needsAttention =>
      this == PaymentStatus.failed || this == PaymentStatus.pending;
}

int _int(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

String _str(dynamic v) => v == null ? '' : v.toString();

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// The customer's contact details, present only on the shop-facing payload.
class OrderCustomer {
  const OrderCustomer({required this.id, required this.name, required this.phoneNumber});

  final int? id;
  final String name;
  final String phoneNumber;

  factory OrderCustomer.fromJson(Map<String, dynamic> json) => OrderCustomer(
        id: json['id'] == null ? null : _int(json['id']),
        name: _str(json['name']),
        phoneNumber: _str(json['phoneNumber']),
      );
}

/// One line of an order. Prices are snapshots taken when the order was placed,
/// so a shop repricing an item never changes what was charged.
class OrderLine {
  const OrderLine({
    required this.id,
    required this.productId,
    required this.name,
    required this.brand,
    required this.sku,
    required this.images,
    required this.quantity,
    required this.unitPricePaise,
    required this.discountPaise,
    required this.lineTotalPaise,
    required this.shopId,
    required this.shopName,
  });

  final int? id;
  final int? productId;
  final String name;
  final String brand;
  final String sku;
  final List<String> images;
  final int quantity;
  final int unitPricePaise;
  final int discountPaise;

  /// Gross (unit x quantity). The order-level discount is deducted once, at
  /// the order level, so the lines sum to the subtotal.
  final int lineTotalPaise;

  final int? shopId;
  final String shopName;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        id: json['id'] == null ? null : _int(json['id']),
        productId: json['productId'] == null ? null : _int(json['productId']),
        name: _str(json['name']),
        brand: _str(json['brand']),
        sku: _str(json['sku']),
        images: (json['images'] as List<dynamic>? ?? const [])
            .map((e) => _str(e))
            .where((e) => e.isNotEmpty)
            .toList(),
        quantity: _int(json['quantity'], 1),
        unitPricePaise: _int(json['unitPricePaise']),
        discountPaise: _int(json['discountPaise']),
        lineTotalPaise: _int(json['lineTotalPaise']),
        shopId: json['shopId'] == null ? null : _int(json['shopId']),
        shopName: _str(json['shopName']),
      );

  String? get thumbnail => images.isEmpty ? null : images.first;
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.placedAt,
    required this.updatedAt,
    required this.items,
    required this.itemCount,
    required this.subtotalPaise,
    required this.discountAmountPaise,
    required this.totalAmountPaise,
    this.shippingAddress,
    this.customer,
    this.shippingAddressText = '',
  });

  final int id;
  final String orderNumber;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DateTime? placedAt;
  final DateTime? updatedAt;
  final List<OrderLine> items;
  final int itemCount;

  /// subtotal - discount == total. Guaranteed by the DTO, so the client can
  /// render a receipt that adds up without recomputing anything.
  final int subtotalPaise;
  final int discountAmountPaise;
  final int totalAmountPaise;

  final Address? shippingAddress;

  /// Shop-facing only.
  final OrderCustomer? customer;
  final String shippingAddressText;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: _int(json['id']),
        orderNumber: _str(json['orderNumber']),
        status: OrderStatus.fromWire(json['status'] as String?),
        paymentStatus: PaymentStatus.fromWire(json['paymentStatus'] as String?),
        placedAt: _date(json['placedAt']),
        updatedAt: _date(json['updatedAt']),
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(OrderLine.fromJson)
            .toList(),
        itemCount: _int(json['itemCount']),
        subtotalPaise: _int(json['subtotalPaise']),
        discountAmountPaise: _int(json['discountAmountPaise']),
        totalAmountPaise: _int(json['totalAmountPaise']),
        shippingAddress: json['shippingAddress'] is Map<String, dynamic>
            ? Address.fromJson(json['shippingAddress'] as Map<String, dynamic>)
            : null,
        customer: json['customer'] is Map<String, dynamic>
            ? OrderCustomer.fromJson(json['customer'] as Map<String, dynamic>)
            : null,
        shippingAddressText: _str(json['shippingAddressText']),
      );

  /// The shops this order draws from. One today; the cart is single-shop, but
  /// OrderItem already carries a shop id per line.
  List<String> get shopNames =>
      items.map((i) => i.shopName).where((n) => n.isNotEmpty).toSet().toList();

  bool get hasDiscount => discountAmountPaise > 0;

  Order copyWith({OrderStatus? status, PaymentStatus? paymentStatus}) => Order(
        id: id,
        orderNumber: orderNumber,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        placedAt: placedAt,
        updatedAt: updatedAt,
        items: items,
        itemCount: itemCount,
        subtotalPaise: subtotalPaise,
        discountAmountPaise: discountAmountPaise,
        totalAmountPaise: totalAmountPaise,
        shippingAddress: shippingAddress,
        customer: customer,
        shippingAddressText: shippingAddressText,
      );
}
