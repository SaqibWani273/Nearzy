// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_model1.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopModel1 _$ShopModel1FromJson(Map<String, dynamic> json) => ShopModel1(
      id: (json['id'] as num?)?.toInt(),
      user: BasicUserModel.fromJson(json['myUser'] as Map<String, dynamic>),
      description: json['description'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      ownerPicUrl: json['ownerPicUrl'] as String,
      locationInfo:
          LocationInfo.fromJson(json['locationInfo'] as Map<String, dynamic>),
      ownerName: json['ownerName'] as String,
      shopPicUrl: json['shopPicUrl'] as String,
      pancardPicUrl: json['pancardPicUrl'] as String,
      ownerIdPicUrl: json['ownerIdPicUrl'] as String,
      businessLicense: json['businessLicense'] as String,
      address: json['address'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );

Map<String, dynamic> _$ShopModel1ToJson(ShopModel1 instance) =>
    <String, dynamic>{
      'id': instance.id,
      'myUser': instance.user.toJson(),
      'description': instance.description,
      'categories': instance.categories,
      'ownerPicUrl': instance.ownerPicUrl,
      'locationInfo': instance.locationInfo.toJson(),
      'ownerName': instance.ownerName,
      'shopPicUrl': instance.shopPicUrl,
      'pancardPicUrl': instance.pancardPicUrl,
      'ownerIdPicUrl': instance.ownerIdPicUrl,
      'businessLicense': instance.businessLicense,
      'address': instance.address,
      'phoneNumber': instance.phoneNumber,
    };

LocationInfo _$LocationInfoFromJson(Map<String, dynamic> json) => LocationInfo(
      completeAddress: json['completeAddress'] as String,
      shortAddress: json['shortAddress'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longtitude: (json['longtitude'] as num).toDouble(),
    );

Map<String, dynamic> _$LocationInfoToJson(LocationInfo instance) =>
    <String, dynamic>{
      'completeAddress': instance.completeAddress,
      'shortAddress': instance.shortAddress,
      'latitude': instance.latitude,
      'longtitude': instance.longtitude,
    };
