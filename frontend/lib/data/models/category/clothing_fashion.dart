// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'specific_category/specific_category.dart';

class ClothingFashionCategory extends SpecificCategory {
  final String size;
  final String material;
  final Gender gender;
  final FitType? fitType;
  final Season? season;
  final String name;
  /* more attributes 
List<Color> colors;

  */
  ClothingFashionCategory({
    required this.name,
    required this.size,
    required this.material,
    required this.gender,
    this.fitType,
    this.season,
  }) : super(name: name);

  factory ClothingFashionCategory.fromMap(Map<String, dynamic> map) {
    return ClothingFashionCategory(
      name: map['name'] as String,
      size: map['size'] as String,
      material: map['material'] as String,
      gender: genderFromString(map['gender'] as String),
      fitType: fitTypeFromString(map['fitType'] as String),
      season: seasonFromString(map['season'] as String),
    );
  }

  // String toJson() => json.encode(toMap());

  // factory ClothingFashionCategory.fromJson(String source) => ClothingFashionCategory.fromMap(json.decode(source) as Map<String, dynamic>);
}

//string to enum for FitType

FitType fitTypeFromString(String fitType) {
  return FitType.values
      .firstWhere((element) => element.name.toLowerCase() == fitType);
}

enum FitType { slim, regular, loose }

//string to enum for Gender

Gender genderFromString(String gender) {
  return Gender.values
      .firstWhere((element) => element.name.toLowerCase() == gender);
}

enum Gender { men, women, unisex }

//string to enum for Season

Season seasonFromString(String season) {
  return Season.values
      .firstWhere((element) => element.name.toLowerCase() == season);
}

enum Season { winter, summer, all }
