// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:convert';

// import '/data/models/category/product_category.dart';
// import '/data/models/customer.dart';
// import '/data/models/basic_user_model.dart';

// class ShopModel extends UserModel {
//   // String name;
//   int? id;
//   BasicUserModel user;
//   String description;
//   List<ProductCategory> categories;
//   String image;
//   Address location;
//   ContactInfo contactInfo;
//   // String ownerName;
//   // String shopPicUrl;
//   // String pancardPicUrl;
//   // String ownerIdPicUrl;
//   // String businessLicense;
//   //int phoneNumber

//   ShopModel({
//     // required this.name,
//     required this.user,
//     required this.image,
//     required this.categories,
//     required this.description,
//     required this.location,
//     required this.contactInfo,
//     this.id,
//   });

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'id': id,
//       'myUser': user.toMap(),
//       // 'name': user.username,
//       // 'description': description,
//       // 'categories': categories.map((x) => x.toMap()).toList(),
//       // 'image': image,
//       // 'location': location.toMap(),
//       'contactInfo': contactInfo.toMap(),
//     };
//   }

//   factory ShopModel.fromMap(Map<String, dynamic> map) {
//     return ShopModel(
//       id: map['id'] as int,
//       user: BasicUserModel.fromMap(map['myUser'] as Map<String, dynamic>),
//       description: map['description'] as String,
//       categories: [],
//       //  List<ProductCategory>.from(
//       //   (map['categories'] as List<int>).map<ProductCategory>(
//       //     (x) => ProductCategory.fromMap(x as Map<String, dynamic>),
//       //   ),
//       // ),
//       image: map['imageUrl'] as String,
//       location: Address(
//           completeAddress: '',
//           latitude: 0.0,
//           longitude: 0.0,
//           locationName:
//               ''), //Address.fromMap(map['location'] as Map<String, dynamic>),
//       contactInfo: ContactInfo(phone: 0, email: '', website: ''),
//       // ContactInfo.fromMap(map['contactInfo'] as Map<String, dynamic>),
//     );
//   }

//   // String toJson() => json.encode(toMap());

//   factory ShopModel.fromJson(String source) =>
//       ShopModel.fromMap(json.decode(source) as Map<String, dynamic>);
// }

// class Address {
//   double latitude;
//   double longitude;
//   String completeAddress;
//   String locationName;
//   Address({
//     required this.latitude,
//     required this.longitude,
//     required this.completeAddress,
//     required this.locationName,
//   });

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'latitude': latitude,
//       'longitude': longitude,
//       'completeAddress': completeAddress,
//       'locationName': locationName,
//     };
//   }

//   factory Address.fromMap(Map<String, dynamic> map) {
//     return Address(
//       latitude: map['latitude'] as double,
//       longitude: map['longitude'] as double,
//       completeAddress: map['completeAddress'] as String,
//       locationName: map['locationName'] as String,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory Address.fromJson(String source) =>
//       Address.fromMap(json.decode(source) as Map<String, dynamic>);
// }

// class ContactInfo {
//   int phone;
//   String email;
//   String? website;
//   ContactInfo({
//     required this.phone,
//     required this.email,
//     this.website,
//   });

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'phone': phone,
//       'email': email,
//       'website': website,
//     };
//   }

//   factory ContactInfo.fromMap(Map<String, dynamic> map) {
//     return ContactInfo(
//       phone: map['phone'] as int,
//       email: map['email'] as String,
//       website: map['website'] != null ? map['website'] as String : null,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory ContactInfo.fromJson(String source) =>
//       ContactInfo.fromMap(json.decode(source) as Map<String, dynamic>);
// }
