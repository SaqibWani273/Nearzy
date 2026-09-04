// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:nearzy/data/models/order.dart';

import '/data/models/cart.dart';

import 'basic_user_model/basic_user_model.dart';

//UserModel is used to check user-type during app startup
abstract class UserModel {}

class Customer extends UserModel {
  final int? id;

  List<CartItem>? cartItems;
  BasicUserModel user;
  List<Order>? orders;
  Customer({required this.user, this.cartItems, this.id, required this.orders});

  Customer copyWith({
    BasicUserModel? user,
    List<CartItem>? cartItems,
    List<Order>? orders,
  }) {
    return Customer(
      user: user ?? this.user,
      cartItems: cartItems ?? this.cartItems,
      id: id,
      orders: orders ?? this.orders,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'myUser': user.toJson(),
      'cartItems': cartItems?.map((cartItem) => cartItem.toMap()).toList(),
      // Orders are intentionally absent: they are loaded from their own
      // endpoint and never sent back. The old code dereferenced a nullable
      // list here, which would have thrown for any customer whose orders
      // had not loaded yet.
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] != null ? map['id'] as int : null,
      user: BasicUserModel.fromJson(map['myUser'] as Map<String, dynamic>),
      // toCustomerDto deliberately omits orders: the client loads them
      // from /customer/orders and treats null as "not loaded yet". The
      // previous code read map["order"] (singular), a key nothing ever
      // sent, while toMap wrote "orders" — so this was dead either way.
      orders: null,
      cartItems: map['cartItems'] == null
          ? null
          : List<CartItem>.from(
              (map['cartItems'] as List<dynamic>).map<CartItem>(
                (x) => CartItem.fromMap(x as Map<String, dynamic>),
              ),
            ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Customer.fromJson(String source) =>
      Customer.fromMap(json.decode(source) as Map<String, dynamic>);

  // @override
  // String toString() => 'Customer(user: $user)';

  // @override
  // bool operator ==(covariant Customer other) {
  //   if (identical(this, other)) return true;

  //   return other.user == user;
  // }

  // @override
  // int get hashCode => user.hashCode;
}
