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

  // ── Discovery fields ──────────────────────────────────────────────────
  // Populated by /customer/shops-near-location. Null when the shop came from
  // an endpoint that doesn't compute them (e.g. the shop's own profile), so
  // every consumer must degrade gracefully.

  /// The shop's trading name. Falls back to the owner's login handle, which
  /// is what the UI used to show by mistake.
  String? name;

  String? slug;

  /// Straight-line km from the location the customer is browsing from.
  double? distanceKm;

  bool? isVerified;

  int? productCount;

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
    this.name,
    this.slug,
    this.distanceKm,
    this.isVerified,
    this.productCount,
  });

  /// What to show as the shop's title, in preference order.
  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return user.username;
  }

  /// "450 m" / "1.2 km" / "12 km" — null when distance is unknown.
  String? get distanceLabel {
    final d = distanceKm;
    if (d == null) return null;
    if (d < 1) return '${(d * 1000).round()} m';
    if (d < 10) return '${d.toStringAsFixed(1)} km';
    return '${d.round()} km';
  }

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
    String? name,
    String? slug,
    double? distanceKm,
    bool? isVerified,
    int? productCount,
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
      name: name ?? this.name,
      slug: slug ?? this.slug,
      distanceKm: distanceKm ?? this.distanceKm,
      isVerified: isVerified ?? this.isVerified,
      productCount: productCount ?? this.productCount,
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
        completeAddress: "Lal Chowk, Srinagar, Jammu and Kashmir, 190001",
        shortAddress: "Srinagar 190001",
        latitude: 34.083656,
        longtitude: 74.797371,
      );

  /// Guards against rows that reached the client with no coordinates — a
  /// (0,0) marker in the Gulf of Guinea is worse than no marker at all.
  bool get hasCoordinates => latitude != 0 || longtitude != 0;

  LocationInfo copyWith({
    String? completeAddress,
    String? shortAddress,
    double? latitude,
    double? longtitude,
  }) =>
      LocationInfo(
        completeAddress: completeAddress ?? this.completeAddress,
        shortAddress: shortAddress ?? this.shortAddress,
        latitude: latitude ?? this.latitude,
        longtitude: longtitude ?? this.longtitude,
      );
  Map<String, dynamic> toJson() => _$LocationInfoToJson(this);

  factory LocationInfo.fromJson(Map<String, dynamic> json) =>
      _$LocationInfoFromJson(json);
}
