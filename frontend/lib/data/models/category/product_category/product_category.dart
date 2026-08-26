// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:json_annotation/json_annotation.dart';
part 'product_category.g.dart';

//This Model is needed to show the product categories in the customer-Dashboard
@JsonSerializable()
class ProductCategory {
  int id;
  String name;
  String description;
  String image;
  bool isTopProductCategory;

  ProductCategory({
    required this.id,
    required this.name,
    required this.image,
    required this.isTopProductCategory,
    required this.description,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      _$ProductCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ProductCategoryToJson(this);
}
