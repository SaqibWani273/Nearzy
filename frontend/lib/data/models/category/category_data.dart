//this model is used at the time of uploading a product in
//shop module
import 'package:json_annotation/json_annotation.dart';
part 'category_data.g.dart';

@JsonSerializable()
class CategoryData {
  final String name;
  final String image;
  final CategoryFields? mustFields;
  final CategoryFields? optionalFields;
  CategoryData({
    required this.name,
    required this.image,
    required this.mustFields,
    required this.optionalFields,
  });
  factory CategoryData.fromJson(Map<String, dynamic> json) =>
      _$CategoryDataFromJson(json);
  // factory CategoryData.fromMap(Map<String, dynamic> map) {
  //   final mustFields = map['catSpecificMustAttributes'];
  //   final optionalFields = map['catSpecificOptionalAttributes'];
  //   return CategoryData(
  //     name: map['name'] as String,
  //     image: map['imageUrl'] as String,
  //     mustFields:
  //         mustFields == null ? null : CategoryFields.fromMap(mustFields),
  //     optionalFields: optionalFields == null
  //         ? null
  //         : CategoryFields.fromMap(optionalFields),
  //   );
  // }
}

@JsonSerializable()
class CategoryFields {
  final List<String>? stringAttributes;
  final List<String>? boolAttributes;
  // final List<Map<String, List<String>>>? enumAttributes;
  final Map<String, List<String>>? enumAttributes;
  CategoryFields({
    required this.stringAttributes,
    required this.boolAttributes,
    required this.enumAttributes,
  });
  factory CategoryFields.fromJson(Map<String, dynamic> json) =>
      _$CategoryFieldsFromJson(json);
  // factory CategoryFields.fromMap(Map<String, dynamic> map) {
  //   final Map<String, dynamic>? enumAttMap = map["enumAttributes"];
  //   return CategoryFields(
  //     stringAttributes: (map['stringAttributes'] as List<dynamic>?)
  //         ?.map((e) => e as String)
  //         .toList(),
  //     boolAttributes: (map['boolAttributes'] as List<dynamic>?)
  //         ?.map((e) => e as bool)
  //         .toList(),
  //     enumAttributes: enumAttMap == null || enumAttMap.isEmpty
  //         ? null
  //         :
  //         //     (map['enumAttributes'] as Map<String, dynamic>?)?.entries.map(
  //         //   (entry) => {
  //         //     entry.key: (entry.value as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  //         //   }
  //         // ) as Map<>

  //         Map.fromIterable(enumAttMap.entries.map((e) => {
  //               e.key: (e.value as List<dynamic>)
  //                   .map((e) => (e as String))
  //                   .toList()
  //             })),
  //   );
  // }
}
