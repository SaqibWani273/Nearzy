// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:json_annotation/json_annotation.dart';

import '../basic_user_model/basic_user_model.dart';
import '../customer.dart';

part 'shop_model1.g.dart';

@JsonSerializable()
class ShopModel1 extends UserModel {
  int? id;
  BasicUserModel user;
  String description;
  List<String> categories;
  String ownerPicUrl;
  LocationInfo locationInfo;
  String ownerName;
  String shopPicUrl;
  String pancardPicUrl;
  String ownerIdPicUrl;
  String businessLicense;
  String address;
  String phoneNumber;
  ShopModel1({
    this.id,
    required this.user,
    required this.description,
    required this.categories,
    required this.ownerPicUrl,
    required this.locationInfo,
    required this.ownerName,
    required this.shopPicUrl,
    required this.pancardPicUrl,
    required this.ownerIdPicUrl,
    required this.businessLicense,
    required this.address,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => _$ShopModel1ToJson(this);
  factory ShopModel1.fromJson(Map<String, dynamic> json) =>
      _$ShopModel1FromJson(json);

  ShopModel1 copyWith({
    int? id,
    BasicUserModel? user,
    String? description,
    List<String>? categories,
    String? ownerPicUrl,
    LocationInfo? locationInfo,
    String? ownerName,
    String? shopPicUrl,
    String? pancardPicUrl,
    String? ownerIdPicUrl,
    String? businessLicense,
    String? address,
    String? phoneNumber,
  }) {
    return ShopModel1(
      id: id ?? this.id,
      user: user ?? this.user,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      ownerPicUrl: ownerPicUrl ?? this.ownerPicUrl,
      locationInfo: locationInfo ?? this.locationInfo,
      ownerName: ownerName ?? this.ownerName,
      shopPicUrl: shopPicUrl ?? this.shopPicUrl,
      pancardPicUrl: pancardPicUrl ?? this.pancardPicUrl,
      ownerIdPicUrl: ownerIdPicUrl ?? this.ownerIdPicUrl,
      businessLicense: businessLicense ?? this.businessLicense,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

@JsonSerializable()
class LocationInfo {
  final String completeAddress;
  final String shortAddress;
  final double latitude;
  final double longtitude;
  LocationInfo({
    required this.completeAddress,
    required this.shortAddress,
    required this.latitude,
    required this.longtitude,
  });
  factory LocationInfo.defaultValue() => LocationInfo(
        completeAddress: "",
        shortAddress: "Srinagar,190001 J&K",
        latitude: 34.083656,
        longtitude: 74.797371,
      );
  Map<String, dynamic> toJson() => _$LocationInfoToJson(this);

  factory LocationInfo.fromJson(Map<String, dynamic> json) =>
      _$LocationInfoFromJson(json);
}
