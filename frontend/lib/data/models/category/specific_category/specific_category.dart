import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'specific_category.g.dart';

@JsonSerializable()
class SpecificCategory {
  final String name;
  SpecificCategory({
    required this.name,
  });

  factory SpecificCategory.fromJson(Map<String, Object?> json) =>
      _$SpecificCategoryFromJson(json);
  Map<String, Object?> toJson() => _$SpecificCategoryToJson(this);
}

class GeneralSpecificCategory extends SpecificCategory {
  //if a category has must-have attributes, add them at the time
  //of adding the product
  SpecificAttributesMap? mustHaveSpecificAttributes;
  SpecificAttributesMap? canHaveSpecificAttributes;
  String name;
  GeneralSpecificCategory({
    this.canHaveSpecificAttributes,
    this.mustHaveSpecificAttributes,
    required this.name,
  }) : super(name: name);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mustHaveSpecificAttributes': mustHaveSpecificAttributes?.toMap(),
      'canHaveSpecificAttributes': canHaveSpecificAttributes?.toMap(),
      'name': name,
    };
  }

  factory GeneralSpecificCategory.fromJson(Map<String, dynamic> map) {
    return GeneralSpecificCategory(
      mustHaveSpecificAttributes: map['mustHaveSpecificAttributes'] != null
          ? SpecificAttributesMap.fromMap(
              map['mustHaveSpecificAttributes'] as Map<String, dynamic>)
          : null,
      canHaveSpecificAttributes: map['canHaveSpecificAttributes'] != null
          ? SpecificAttributesMap.fromMap(
              map['canHaveSpecificAttributes'] as Map<String, dynamic>)
          : null,
      name: map['name'] as String,
    );
  }

  // factory GeneralSpecificCategory.fromJson(String source) =>
  //     GeneralSpecificCategory.fromMap(
  //         json.decode(source) as Map<String, dynamic>);

  GeneralSpecificCategory copyWith({
    SpecificAttributesMap? mustHaveSpecificAttributes,
    SpecificAttributesMap? canHaveSpecificAttributes,
    String? name,
  }) {
    return GeneralSpecificCategory(
      mustHaveSpecificAttributes:
          mustHaveSpecificAttributes ?? this.mustHaveSpecificAttributes,
      canHaveSpecificAttributes:
          canHaveSpecificAttributes ?? this.canHaveSpecificAttributes,
      name: name ?? this.name,
    );
  }

  @override
  String toString() =>
      'GeneralSpecificCategory(mustHaveSpecificAttributes: $mustHaveSpecificAttributes, canHaveSpecificAttributes: $canHaveSpecificAttributes, name: $name)';
}

/*
SpecificAttributesMap Strucutre - >
{
"boolAttributes" : {
"boolAttribute1" : true,
"boolAttribute2" : false,
},
"stringAttributes" : {
"stringAttribute1" : "value1",
"stringAttribute2" : "value2",
},
"enumAttributes" : {
"enumAttribute1" : "any option"
// "enumAttribute2" : ["option1", "option2"],
}
}

*/
class SpecificAttributesMap {
  final Map<String, String> stringAttributes;
  final Map<String, bool> boolAttributes;
  final Map<String, String> enumAttributes;
  SpecificAttributesMap({
    required this.stringAttributes,
    required this.boolAttributes,
    required this.enumAttributes,
  });

  SpecificAttributesMap copyWith({
    Map<String, String>? stringAttributes,
    Map<String, bool>? boolAttributes,
    Map<String, String>? enumAttributes,
  }) {
    return SpecificAttributesMap(
      stringAttributes: stringAttributes ?? this.stringAttributes,
      boolAttributes: boolAttributes ?? this.boolAttributes,
      enumAttributes: enumAttributes ?? this.enumAttributes,
    );
  }

  factory SpecificAttributesMap.empty() {
    return SpecificAttributesMap(
      stringAttributes: <String, String>{},
      boolAttributes: <String, bool>{},
      enumAttributes: <String, String>{},
    );
  }
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'stringAttributes': stringAttributes,
      'boolAttributes': boolAttributes,
      'enumAttributes': enumAttributes,
    };
  }

  factory SpecificAttributesMap.fromMap(Map<String, dynamic> map) {
    return SpecificAttributesMap(
        stringAttributes: Map<String, String>.from(
            (map['stringAttributes'] as Map<String, String>)),
        boolAttributes: Map<String, bool>.from(
            (map['boolAttributes'] as Map<String, bool>)),
        enumAttributes: Map<String, String>.from(
          (map['enumAttributes'] as Map<String, String>),
        ));
  }

  String toJson() => json.encode(toMap());

  factory SpecificAttributesMap.fromJson(String source) =>
      SpecificAttributesMap.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'SpecificAttributesMap(stringAttributes: $stringAttributes, boolAttributes: $boolAttributes, enumAttributes: $enumAttributes)';

  @override
  bool operator ==(covariant SpecificAttributesMap other) {
    if (identical(this, other)) return true;

    return mapEquals(other.stringAttributes, stringAttributes) &&
        mapEquals(other.boolAttributes, boolAttributes) &&
        mapEquals(other.enumAttributes, enumAttributes);
  }

  @override
  int get hashCode =>
      stringAttributes.hashCode ^
      boolAttributes.hashCode ^
      enumAttributes.hashCode;
}
