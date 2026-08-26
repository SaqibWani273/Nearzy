import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import '/presentation/common/screens/error_screen.dart';
import '/presentation/common/widgets/loading_widgets.dart';
import '../../../../../data/models/category/specific_category/specific_category.dart';
import '/constants/product_const.dart';

import '../../../../../utils/image_picker.dart';
import '/data/models/category/category_data.dart';
import '/data/models/product.dart';
import '/data/repositories/shop/shop_data_repository.dart';
import '/presentation/common/screens/upload_success_screen.dart';
import '/utils/form_handler.dart';
import '../view_model/shop_bloc.dart';

class UploadProductScreen extends StatefulWidget {
  const UploadProductScreen({super.key});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  late List<String> _formFields;
  Map<String, TextEditingController> _formControllers = {};
  final _formKey = GlobalKey<FormState>();
  XFile? _mainProductImage;
  List<XFile>? _moreProductImages = [];
  //these are used to set category name and attributes...
  CategoryData? _selectedCategory;
  GeneralSpecificCategory _generalSpecificCategory =
      GeneralSpecificCategory(name: '');
  late SpecificAttributesMap _mustHaveSpecificAttributes;

  late SpecificAttributesMap _canHaveSpecificAttributes;

//... till here
  void initState() {
    if (context.read<ShopDataRepository>().categoriesData.isEmpty) {
      context.read<ShopBloc>().add(LoadAllCategoriesEvent());
    } else {
      context.read<ShopBloc>().add(ShopInitialEvent());
    }
    //set to initial state
    resetSpecificCategoryAttributes();
    _formFields = ProductConstants.formFields;

    for (var i = 0; i < _formFields.length; i++) {
      _formControllers[_formFields[i].split(' ')[0]] = TextEditingController();
    }

    _picker = ImagePicker();
    super.initState();
  }

  ImagePicker? _picker;

  Future<void> _getImage() async {
    final image = await getImage(_picker!);

    if (image != null) {
      setState(() {
        _mainProductImage = image;
      });
    } else {
      return;
    }
  }

  Future<void> _getMoreImages() async {
    final image = await getImage(_picker!);
    if (image != null) {
      setState(() {
        _moreProductImages!.add(image);
      });
    }
  }

  void resetSpecificCategoryAttributes() {
    _mustHaveSpecificAttributes = SpecificAttributesMap.empty();
    _canHaveSpecificAttributes = SpecificAttributesMap.empty();
  }

  void updatGenSpecCat(mustAtt, canAtt) {
    _generalSpecificCategory = _generalSpecificCategory.copyWith(
        mustHaveSpecificAttributes: mustAtt, canHaveSpecificAttributes: canAtt);
  }

  void _changeSelectedCategory(CategoryData? category) {
    //reset category data
    _generalSpecificCategory =
        GeneralSpecificCategory(name: category?.name ?? '');
    resetSpecificCategoryAttributes();
    setState(() {
      _selectedCategory = category;
    });
  }

  Widget categoryAttributesWidget(CategoryFields fields, AttributesType type) {
    final List<String> stringFields = fields.stringAttributes ?? [];
    final List<String> boolFields = fields.boolAttributes ?? [];
    final Map<String, List<String>> enumFields = fields.enumAttributes ?? {};
    return Column(
      children: [
        if (stringFields.isNotEmpty)
          ...stringFields
              .map(
                (e) => Column(
                  children: [
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: FormHandler.inputDec(
                          "$e ${type == AttributesType.must ? '**' : ''}"),
                      validator: type == AttributesType.must
                          ? FormHandler.stringValidator
                          : null,
                      onChanged: (value) {
                        type == AttributesType.must
                            ? _mustHaveSpecificAttributes.stringAttributes[e] =
                                value
                            : _canHaveSpecificAttributes.stringAttributes[e] =
                                value;
                        updatGenSpecCat(_mustHaveSpecificAttributes,
                            _canHaveSpecificAttributes);
                      },
                    ),
                    SizedBox(
                      height: 20,
                    )
                  ],
                ),
              )
              .toList(),
        if (boolFields.isNotEmpty)
          ...boolFields.map((e) {
            //set bool values initially to false if not present
            if (type == AttributesType.must &&
                !_mustHaveSpecificAttributes.boolAttributes.containsKey(e)) {
              _mustHaveSpecificAttributes.boolAttributes[e] = false;
              updatGenSpecCat(
                  _mustHaveSpecificAttributes, _canHaveSpecificAttributes);
            }
            if (type == AttributesType.optional &&
                !_canHaveSpecificAttributes.boolAttributes.containsKey(e)) {
              _canHaveSpecificAttributes.boolAttributes[e] = false;
              updatGenSpecCat(
                  _mustHaveSpecificAttributes, _canHaveSpecificAttributes);
            }

            return Row(
              children: [
                Text("$e ${type == AttributesType.must ? '**' : ''}"),
                SizedBox(width: 10),
                Switch(
                  value: type == AttributesType.must
                      ? _mustHaveSpecificAttributes.boolAttributes[e]!
                      : _canHaveSpecificAttributes.boolAttributes[e]!,
                  onChanged: (value) {
                    log("$value");
                    setState(() {
                      type == AttributesType.must
                          ? _mustHaveSpecificAttributes.boolAttributes[e] =
                              value
                          : _canHaveSpecificAttributes.boolAttributes[e] =
                              value;
                      updatGenSpecCat(_mustHaveSpecificAttributes,
                          _canHaveSpecificAttributes);
                    });
                  },
                ),
              ],
            );
          }).toList(),
        if (enumFields.isNotEmpty)
          ...enumFields.entries
              .map(
                (MapEntry<String, List<String>> e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: null, //categories[0].name,
                    validator: FormHandler.nullCheck,
                    items: e.value
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      type == AttributesType.must
                          ? _mustHaveSpecificAttributes
                              .enumAttributes["${e.key}"] = value
                          : _canHaveSpecificAttributes
                              .enumAttributes["${e.key}"] = value;
                      updatGenSpecCat(_mustHaveSpecificAttributes,
                          _canHaveSpecificAttributes);
                    },
                    decoration: InputDecoration(
                        labelText:
                            'Select a ${e.key} ${type == AttributesType.must ? '**' : ''}'),
                  ),
                ),
              )
              .toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var deviceHeight = MediaQuery.of(context).size.height;
    var deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(body: SafeArea(
      child: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, state) {
          if (state is ShopLoadingState) {
            return LoadingWidgets.SpinKitFading(deviceWidth);
          }
          if (state is ShopUploadedProductState) {
            return UploadSuccessScreen();
          }
          if (state is ShopErrorState) {
            return ErrorScreen(
              customException: state.customException,
              onTryAgainPressed: () =>
                  context.read<ShopBloc>().add(ShopInitialEvent()),
            );
          }
          // if (state is ShopLoadedAllCategoriesState) {
          final List<CategoryData> categories =
              context.read<ShopDataRepository>().categoriesData;
          return SingleChildScrollView(
            primary: true,
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text("Fields Marked with ** are Compulsory"),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _getImage,
                    child: _mainProductImage == null
                        ? Container(
                            height: deviceHeight * 0.2,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              // border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image),
                                  Text('Select Main Image **'),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            height: 200.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: kIsWeb
                                  ? Image.network(_mainProductImage!.path)
                                  : Image.file(File(_mainProductImage!.path)),
                            ),
                          ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                            icon: Icon(Icons.image),
                            onPressed: _getMoreImages,
                            label: Text("add another")),
                        ..._moreProductImages!
                            .map(
                              (e) => Container(
                                height: 50.0,
                                margin: EdgeInsets.symmetric(horizontal: 8.0),
                                width: deviceWidth * 0.2,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: kIsWeb
                                      ? FadeInImage.assetNetwork(
                                          placeholder:
                                              'assets/images/placeholder.jpg',
                                          image: e.path,
                                          fit: BoxFit.cover,
                                        )
                                      : FadeInImage(
                                          placeholder: AssetImage(
                                              'assets/images/placeholder.jpg'),
                                          image: FileImage(File(e.path)),
                                          fit: BoxFit.cover,
                                        ),
                                  //  Image.network(e.path)
                                  // : Image.file(File(e.path)),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ..._formFields.map((e) {
                    final bool isNumField = e.split(' ')[0] == 'price' ||
                        e.split(' ')[0] == 'stockQuantity';
                    return Column(
                      children: [
                        TextFormField(
                          //move to next field
                          textInputAction: TextInputAction.next,
                          controller: _formControllers[e.split(' ')[0]],
                          decoration: FormHandler.inputDec(e),
                          keyboardType:
                              isNumField ? TextInputType.number : null,
                          inputFormatters: isNumField
                              ? [
                                  FilteringTextInputFormatter.digitsOnly,
                                ]
                              : null,
                          validator:
                              isNumField ? null : FormHandler.stringValidator,
                        ),
                        SizedBox(
                          height: 20,
                        )
                      ],
                    );
                  }
                      // SizedBox(
                      //   height: 20,
                      // ),
                      ).toList(),
                  DropdownButtonFormField<CategoryData?>(
                    value: null, //categories[0].name,
                    validator: FormHandler.nullCheck,
                    items: categories
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: _changeSelectedCategory,
                    decoration: InputDecoration(labelText: 'Select a category'),
                  ),
                  if (_selectedCategory != null)
                    Column(children: [
                      if (_selectedCategory!.mustFields != null)
                        categoryAttributesWidget(_selectedCategory!.mustFields!,
                            AttributesType.must),
                      if (_selectedCategory!.optionalFields != null)
                        categoryAttributesWidget(
                            _selectedCategory!.optionalFields!,
                            AttributesType.optional),
                    ]),
                  SizedBox(height: 40),
                  // Submit button
                  ElevatedButton(
                    onPressed: () async {
                      log('${_generalSpecificCategory.toString()}');
                      if (_formKey.currentState!.validate()) {
                        if (_mainProductImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please select a main image'),
                            ),
                          );
                          return;
                        }
                        List<Object> moreImages = [];
                        _moreProductImages!.forEach((element) async {
                          kIsWeb
                              ? moreImages.add(await element.readAsBytes())
                              : moreImages.add(element.path);
                        });
                        final List<Object> imageObjects = [
                          kIsWeb
                              ? await _mainProductImage!.readAsBytes()
                              : _mainProductImage!.path,
                          ...moreImages
                        ];
                        context.read<ShopBloc>().add(UploadProductEvent(
                            product: Product(
                              name: _formControllers['name']!.text.trim(),
                              brand: _formControllers['brand']!.text.trim(),
                              shortDescription:
                                  _formControllers['shortDescription']!
                                      .text
                                      .trim(),
                              images: [], //will get updated before uploading the product to db
                              price: int.parse(
                                  _formControllers['price']!.text.trim()),
                              completeDescription:
                                  _formControllers['completeDescription']!
                                      .text
                                      .trim(),
                              shop:
                                  context.read<ShopDataRepository>().shopModel!,
                              stockQuantity: int.parse(
                                  _formControllers['stockQuantity']!
                                      .text
                                      .trim()),
                              category: _generalSpecificCategory,
                              colors: [],
                              available: true,
                              sku: _formControllers['sku']!.text.trim(),
                            ),
                            images: imageObjects));
                      }
                    },
                    child: const Text('Upload '),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ));
  }
}

enum AttributesType { must, optional }
