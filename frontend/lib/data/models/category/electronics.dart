// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'specific_category/specific_category.dart';

class ElectronicsCategory extends SpecificCategory {
  final String brand;
  final String warrantyPeriod;
  final String name;

  ElectronicsCategory({
    required this.brand,
    required this.warrantyPeriod,
    required this.name,
  }) : super(name: name);

  factory ElectronicsCategory.fromMap(Map<String, dynamic> map) {
    return ElectronicsCategory(
      name: map['name'] as String,
      brand: map['brand'] as String,
      warrantyPeriod: map['warrantyPeriod'] as String,
    );
  }

  // String toJson() => json.encode(toMap());

  // factory ElectronicsCategory.fromJson(String source) => ElectronicsCategory.fromMap(json.decode(source) as Map<String, dynamic>);
}

//string to enum for ElectronicsType
// ElectronicsType electronicsTypeFromString(String name) {
//   return ElectronicsType.values.firstWhere((element) => element.name == name);
// }

// enum ElectronicsType { laptop, mobile, tv, others }
