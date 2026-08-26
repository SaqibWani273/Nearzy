
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import '../../../../../../data/repositories/shop/shop_data_repository.dart';
// import '../../../../../common/widgets/image_upload_field.dart';
// import '../../../../../common/widgets/location_widget.dart';

// class OtherShopDetailsWidget extends StatefulWidget {
//   const OtherShopDetailsWidget({
//     super.key,
//   });

//   @override
//   State<OtherShopDetailsWidget> createState() => _OtherShopDetailsWidgetState();
// }

// class _OtherShopDetailsWidgetState extends State<OtherShopDetailsWidget> {
//   //pictures could be file path(i.e. String) for Web or Unit8List for mobile
//   Object? _shopPic;
//   Object? _ownerPic;
//   Object? _pancardPic;
//   Object? _ownerIdPic;
//   String? _locationName;
//   String? _businessLicense;
//   String? _address;
//   String? _ownerName;
//   int? _phoneNumber;
//   String? _shopDescription;
//   List<String> selectedCategories = [];
//   // ImagePicker? _picker;
//   late final List<String> categories;

//   GlobalKey<FormState> formKey = GlobalKey<FormState>();
//   bool checkImagesFilled() {
//     if (_shopPic == null ||
//         _ownerPic == null ||
//         _pancardPic == null ||
//         _ownerIdPic == null) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text('Please upload all images'),
//       ));
//       return false;
//     }
//     return true;
//   }

//   Map<String, dynamic> getOtherShopDetails() {
//     return {
//       'ownerName': _ownerName!,
//       'shopPic': _shopPic,
//       'ownerPic': _ownerPic,
//       'pancardPic': _pancardPic,
//       'ownerIdPic': _ownerIdPic,
//       'locationName': _locationName!,
//       'businessLicense': _businessLicense!,
//       'phoneNumber': _phoneNumber!,
//       'categories': selectedCategories,
//       'address': _address!,
//       'shopDescription': _shopDescription!,
//     };
//   }

//   void addToSelectedCategories(String category) {
//     setState(() {
//       selectedCategories.add(category);
//     });
//   }

//   @override
//   void initState() {
//     categories = context
//         .read<ShopDataRepository>()
//         .categoriesData
//         .map((e) => e.name)
//         .toList();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     var deviceHeight = MediaQuery.of(context).size.height;

//     var deviceWidth = MediaQuery.of(context).size.width;
//     return Form(
//         key: formKey,
//         child: Column(
//           children: [
//             ImageUploadField(
//               onUpload: (imgObject) => _shopPic = imgObject,
//               hintText: "Front Side of Shop",
//               imageHeight: deviceHeight * 0.2,
//               placeholderHeight: deviceHeight * 0.1,
//             ),
//             Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text("Breif About Your Shop"),
//               TextFormField(
//                 textInputAction: TextInputAction.next,
//                 decoration: InputDecoration(
//                   labelText: 'Enter Short Breif About Your Shop',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter proper Breif About Your Shop';
//                   }
//                   return null;
//                 },
//                 onSaved: (value) => _shopDescription = value,
//               ),
//               SizedBox(height: 20.0),
//             ]),
//             //shop location
//             ShopLocationWidget(),
//             Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text("Proper Shop Address"),
//               TextFormField(
//                 textInputAction: TextInputAction.next,
//                 maxLines: 2,
//                 decoration: InputDecoration(
//                   labelText:
//                       'E.g. Letpora,Pampore,Pulwama,Srinagar,Jammu & Kashmir',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter valid Business License Number';
//                   }
//                   return null;
//                 },
//                 onSaved: (value) => _address = value,
//               ),
//               SizedBox(height: 20.0),
//             ]),
//             Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text("Business License Number"),
//               TextFormField(
//                 textInputAction: TextInputAction.next,

//                 decoration: InputDecoration(
//                   labelText: 'Enter Proper Business License Number',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter valid Business License Number';
//                   }
//                   return null;
//                 },
//                 onSaved: (value) =>
//                     _businessLicense = value, // Update _password on save
//               ),
//               SizedBox(height: 20.0),
//             ]),
//             ImageUploadField(
//               onUpload: (imgObject) => _ownerPic = imgObject,
//               hintText: "Shop Owner Picture",
//               imageHeight: deviceHeight * 0.2,
//               placeholderHeight: deviceHeight * 0.1,
//             ),
//             Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text("Owner Name"),
//               TextFormField(
//                 textInputAction: TextInputAction.next,
//                 decoration: InputDecoration(
//                   labelText: 'Registered Shop Owner Name',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter Proper name ';
//                   }
//                   return null;
//                 },
//                 onSaved: (value) => _ownerName = value,
//               ),
//               SizedBox(height: 20.0),
//             ]),
//             ImageUploadField(
//               onUpload: (imgObject) => _ownerIdPic = imgObject,
//               hintText: "Owner Id",
//               imageHeight: deviceHeight * 0.2,
//               placeholderHeight: deviceHeight * 0.1,
//             ),
//             SizedBox(height: 20.0),
//             Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text("Mobile Number"),
//               TextFormField(
//                   textInputAction: TextInputAction.next,
//                   keyboardType: TextInputType.phone,
//                   decoration: InputDecoration(
//                     labelText: 'Enter Proper Mobile Number',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter valid Mobile Number';
//                     }
//                     return null;
//                   },
//                   onSaved: (value) {
//                     if (value != null && value.length == 10)
//                       _phoneNumber =
//                           int.tryParse(value); // Update _password on save
//                   }),
//               SizedBox(height: 20.0),
//             ]),
//             ImageUploadField(
//               onUpload: (imgObject) => _pancardPic = imgObject,
//               hintText: "Pancard",
//               imageHeight: deviceHeight * 0.2,
//               placeholderHeight: deviceHeight * 0.1,
//             ),

//             //select
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("Select one or more Categories"),
//                   GridView(
//                     //noscroll

//                     physics: const NeverScrollableScrollPhysics(),
//                     shrinkWrap: true,
//                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                         mainAxisExtent: deviceHeight * 0.1,
//                         crossAxisCount: deviceWidth > 700
//                             ? 3
//                             : deviceWidth < 250
//                                 ? 1
//                                 : 2,
//                         mainAxisSpacing: 0.0),
//                     children: categories.map((e) {
//                       return SizedBox(
//                         child: CheckboxListTile(
//                           contentPadding: EdgeInsets.symmetric(
//                               horizontal: 8.0, vertical: 0.0),
//                           onChanged: (value) {
//                             if (value == true) {
//                               selectedCategories.add(e);
//                             } else {
//                               selectedCategories.remove(e);
//                             }
//                             setState(() {});
//                           },
//                           value: selectedCategories.contains(e),
//                           title: Text(
//                             e,
//                             style: Theme.of(context).textTheme.bodyMedium,
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ],
//               ),
//             ),

//             SizedBox(height: 16.0),
//           ],
//         ));
//   }
// }
