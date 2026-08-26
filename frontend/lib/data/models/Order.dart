// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';

class Order {
  //primarily to show the orders for shop

  final String id;
  final String shippingAddress;
  final String customerPhone;
  final List<ShopOrderItem> orderItems;
  final String totalPrice;
  final String customerName;
  final String status;
  final PaymentStatus? paymentStatus;
  final String createdDate;
  Order({
    required this.id,
    required this.shippingAddress,
    required this.customerPhone,
    required this.orderItems,
    required this.totalPrice,
    required this.customerName,
    required this.status,
    this.paymentStatus = PaymentStatus.PAID,
    required this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'shippingAddress': shippingAddress,
      'customerPhone': customerPhone,
      'orderItems': orderItems.map((x) => x.toMap()).toList(),
      'totalPrice': totalPrice,
      'customerName': customerName,
      'status': status,
      // 'paymentStatus': paymentStatus.toMap(),
      'createdDate': createdDate,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['orderDetails']['id'].toString(),
      shippingAddress: map['orderDetails']['shippingAddress'] as String,
      customerPhone: map['orderDetails']['customerPhone'] as String,
      orderItems: List<ShopOrderItem>.from(
        (map['orderItems'] as List<dynamic>).map(
          (x) => ShopOrderItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      totalPrice: map['orderDetails']['totalPrice'].toString(),
      customerName:
          map['orderDetails']["customer"]["myUser"]['username'] as String,
      status: map['orderDetails']['status'] as String,
      paymentStatus: PaymentStatus.PAID,
      createdDate: map['orderDetails']['createdDate'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Order.fromJson(String source) =>
      Order.fromMap(json.decode(source) as Map<String, dynamic>);

  Order copyWith({
    String? id,
    String? shippingAddress,
    String? customerPhone,
    List<ShopOrderItem>? orderItems,
    String? totalPrice,
    String? customerName,
    String? status,
    PaymentStatus? paymentStatus,
    String? createdDate,
  }) {
    return Order(
      id: id ?? this.id,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      orderItems: orderItems ?? this.orderItems,
      totalPrice: totalPrice ?? this.totalPrice,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}

class ShopOrderItem {
  final String productId;
  final String productName;
  // final String productImageUrl;
  final String quantity;
  final String totalPrice;
  final String sku;
  final String pricePerUnit;
  final List<String> images;
  ShopOrderItem({
    required this.productId,
    required this.productName,
    // required this.productImageUrl,
    required this.quantity,
    required this.totalPrice,
    required this.sku,
    required this.pricePerUnit,
    required this.images,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'productId': productId,
      'productName': productName,
      // 'productImageUrl': productImageUrl,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'sku': sku,
      'pricePerUnit': pricePerUnit,
      'images': images
    };
  }

  factory ShopOrderItem.fromMap(Map<String, dynamic> map) {
    return ShopOrderItem(
      productId: map['product']['id'].toString(),
      productName: map['product']['name'] as String,
      // productImageUrl: map['productImageUrl'] as String,
      quantity: map['quantity'].toString(),
      totalPrice: map['price'].toString(),
      sku: map['product']['sku'] as String,
      pricePerUnit: map['product']['price'].toString(),
      images: List<String>.from(map['product']['images'] as List<dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory ShopOrderItem.fromJson(String source) =>
      ShopOrderItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

enum PaymentStatus { PAID, COD }

enum OrderStatus { PENDING, PROCESSING, SHIPPED, DELIVERED }

OrderStatus stringToOrderStatus(String status) {
  switch (status) {
    case "PENDING":
      return OrderStatus.PENDING;
    case "PROCESSING":
      return OrderStatus.PROCESSING;
    case "SHIPPED":
      return OrderStatus.SHIPPED;
    case "DELIVERED":
      return OrderStatus.DELIVERED;
    default:
      return OrderStatus.PENDING;
  }
}

Color colorForOrderStatus(String status) {
  OrderStatus orderStatus = stringToOrderStatus(status);
  switch (orderStatus) {
    case OrderStatus.PENDING:
      return Colors.orange;
    case OrderStatus.PROCESSING:
      return Colors.blue;
    case OrderStatus.SHIPPED:
      return Colors.green;
    case OrderStatus.DELIVERED:
      return Colors.green;
    default:
      return Colors.orange;
  }
}

List<OrderStatus> orderStatusList = [
  OrderStatus.PENDING,
  OrderStatus.PROCESSING,
  OrderStatus.SHIPPED,
  OrderStatus.DELIVERED
];
String getNextOrderStatus(String status) {
  int index = orderStatusList.indexOf(stringToOrderStatus(status));
  if (index == orderStatusList.length - 1) {
    return status;
  }
  return orderStatusList[index + 1].name;
}
//update order status in way that shop can only change from current status
//to next status
