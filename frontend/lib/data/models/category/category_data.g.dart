// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryData _$CategoryDataFromJson(Map<String, dynamic> json) => CategoryData(
      name: json['name'] as String,
      image: json['imageUrl'] as String,
      mustFields: json['catSpecificMustAttributes'] == null
          ? null
          : CategoryFields.fromJson(
              json['catSpecificMustAttributes'] as Map<String, dynamic>),
      optionalFields: json['catSpecificOptionalAttributes'] == null
          ? null
          : CategoryFields.fromJson(
              json['catSpecificOptionalAttributes'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CategoryDataToJson(CategoryData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'imageUrl': instance.image,
      'catSpecificMustAttributes': instance.mustFields,
      'catSpecificOptionalAttributes': instance.optionalFields,
    };

CategoryFields _$CategoryFieldsFromJson(Map<String, dynamic> json) =>
    CategoryFields(
      stringAttributes: (json['stringAttributes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      boolAttributes: (json['boolAttributes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      enumAttributes: (json['enumAttributes'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$CategoryFieldsToJson(CategoryFields instance) =>
    <String, dynamic>{
      'stringAttributes': instance.stringAttributes,
      'boolAttributes': instance.boolAttributes,
      'enumAttributes': instance.enumAttributes,
    };
