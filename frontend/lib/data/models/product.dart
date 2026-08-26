import 'package:json_annotation/json_annotation.dart';
import '/data/models/shop_model/shop_model1.dart';

import 'category/specific_category/specific_category.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final int? id;
  final String name;
  final String brand;
  final String shortDescription;
  List<String> images;
  final int price;
  final double? discountInPercentage;
  final String completeDescription;
  final ShopModel1 shop;
  final int stockQuantity;
  final double? rating;
  final GeneralSpecificCategory category;
  final List<String>? colors;
  final bool available;
  // final List<ProductReview>? reviews;
  final String sku; //stock keeping unit
  Product({
    this.id,
    required this.name,
    required this.brand,
    required this.shortDescription,
    required this.images,
    required this.price,
    this.discountInPercentage,
    required this.completeDescription,
    required this.shop,
    required this.stockQuantity,
    this.rating,
    required this.category,
    required this.colors,
    required this.available,
    required this.sku,
    // required this.reviews,
  });
  //used at product upload screen by shop module
  void set setImages(List<String> imgUrls) => images = imgUrls;
  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);
  int get disCountedPrice => discountInPercentage == null
      ? price
      :
      //  (price - ((price * discountInPercentage!) / 100).toInt());
      (price - ((discountInPercentage! / 100) * price).toInt());
}

@JsonSerializable()
class ProductReview {
  final String id;

  final String username;
  final String review;
  final String? image;
  final int rating;
  ProductReview({
    required this.id,
    required this.username,
    required this.review,
    this.image,
    required this.rating,
  });
  factory ProductReview.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ProductReviewToJson(this);
}
