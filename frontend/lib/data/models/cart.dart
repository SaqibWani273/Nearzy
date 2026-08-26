// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import '/data/models/product.dart';

// class Cart {
//   final List<CartItem> cartItems;

//   Cart({required this.cartItems});
//   factory Cart.fromMap(Map<String, dynamic> map) {
//     return Cart(
//       cartItems: List<CartItem>.from(
//         (map['cartItems'] as List<int>).map<CartItem>(
//           (x) => CartItem.fromMap(x as Map<String, dynamic>),
//         ),
//       ),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'cartItems': cartItems.map((x) => x.toMap()).toList(),
//     };
//   }

//   String toJson() => json.encode(toMap());

//   factory Cart.fromJson(String source) =>
//       Cart.fromMap(json.decode(source) as Map<String, dynamic>);
// }

class CartItem {
  //just store id here and when user tries to open cart screen
  //
  final int productId;
  int quantity;

  CartItem({required this.productId, required this.quantity});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'productId': productId,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as int,
      quantity: map['quantity'] as int,
    );
  }
  factory CartItem.fromCartItemDetails(
      {required CartItemDetails cartItemDetails}) {
    return CartItem(
      productId: cartItemDetails.product.id!,
      quantity: cartItemDetails.quantity,
    );
  }

  String toJson() => json.encode(toMap());

  factory CartItem.fromJson(String source) =>
      CartItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

class CartItemDetails {
  int quantity;
  final Product product;

  CartItemDetails({required this.quantity, required this.product});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'quantity': quantity,
      'product': product.toJson(),
    };
  }

  factory CartItemDetails.fromMap(Map<String, dynamic> map) {
    return CartItemDetails(
      quantity: map['quantity'] as int,
      product: Product.fromJson(map['product'] as Map<String, dynamic>),
    );
  }
}
