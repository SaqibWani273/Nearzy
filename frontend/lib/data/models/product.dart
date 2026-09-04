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

  /// The category's database id, set only when the shop module is creating a
  /// product. Server responses describe the category with a nested object, so
  /// this stays null on anything read back from the API.
  @JsonKey(includeIfNull: false)
  final int? categoryId;
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
    this.categoryId,
    required this.colors,
    required this.available,
    required this.sku,
    // required this.reviews,
  });
  //used at product upload screen by shop module
  set setImages(List<String> imgUrls) => images = imgUrls;
  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);

  /// The payload `POST /shop/add-product` expects.
  ///
  /// Deliberately not [toJson]: that serialiser exists for reading products
  /// back and emits a nested `shop` and `category` plus a `price` in the
  /// screen's own units. The create endpoint wants ids and paise, and sending
  /// the read shape is what made every upload fail the not-null constraint on
  /// `shop_id` / `category_id`.
  ///
  /// The shop is intentionally absent — the server takes it from the token.
  Map<String, dynamic> toCreateJson() => <String, dynamic>{
        'name': name,
        'categoryId': categoryId,
        'priceInPaise': price,
        'stockQuantity': stockQuantity,
        if (discountInPercentage != null) 'discountPercent': discountInPercentage,
        if (brand.isNotEmpty) 'brand': brand,
        if (sku.isNotEmpty) 'sku': sku,
        if (shortDescription.isNotEmpty) 'shortDescription': shortDescription,
        if (completeDescription.isNotEmpty)
          'completeDescription': completeDescription,
        'available': available,
        'images': images,
        if (colors != null && colors!.isNotEmpty) 'colors': colors,
      };
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
