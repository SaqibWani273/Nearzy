import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '/presentation/common/screens/error_screen.dart';
import '/presentation/common/widgets/loading_widgets.dart';
import '../../../../../data/models/category/specific_category/specific_category.dart';
import '/constants/product_const.dart';
import '/data/models/listing_draft.dart';
import '/utils/exceptions/custom_exception.dart';
import '/presentation/common/animations/cross_fade.dart';
import '/presentation/common/animations/pressable_scale.dart';
import '/services/api_service.dart';
import '/services/cloudinary_service.dart';
import '/theme/app_colors.dart';
import '/theme/app_spacing.dart';
import '/theme/app_text_styles.dart';

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
  late List<ProductFormField> _formFields;
  final Map<String, TextEditingController> _formControllers = {};
  final _formKey = GlobalKey<FormState>();
  XFile? _mainProductImage;
  final List<XFile> _moreProductImages = [];
  //these are used to set category name and attributes...
  CategoryData? _selectedCategory;
  GeneralSpecificCategory _generalSpecificCategory =
      GeneralSpecificCategory(name: '');
  late SpecificAttributesMap _mustHaveSpecificAttributes;

  late SpecificAttributesMap _canHaveSpecificAttributes;

  /// Listing assistant state. A draft is a suggestion the owner confirms, so
  /// it is kept only to show what still needs checking — every field stays
  /// editable and the controllers remain the source of truth on submit.
  bool _readingPacket = false;
  ListingDraft? _draft;
  String? _draftError;

//... till here
  @override
  void initState() {
    if (context.read<ShopDataRepository>().categoriesData.isEmpty) {
      context.read<ShopBloc>().add(LoadAllCategoriesEvent());
    } else {
      context.read<ShopBloc>().add(ShopInitialEvent());
    }
    //set to initial state
    resetSpecificCategoryAttributes();
    _formFields = ProductConstants.formFields;

    for (final field in _formFields) {
      _formControllers[field.key] = TextEditingController();
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
        _moreProductImages.add(image);
      });
    }
  }

  void resetSpecificCategoryAttributes() {
    _mustHaveSpecificAttributes = SpecificAttributesMap.empty();
    _canHaveSpecificAttributes = SpecificAttributesMap.empty();
  }

  void updatGenSpecCat(
      SpecificAttributesMap mustAtt, SpecificAttributesMap canAtt) {
    _generalSpecificCategory = _generalSpecificCategory.copyWith(
        mustHaveSpecificAttributes: mustAtt, canHaveSpecificAttributes: canAtt);
  }

  /// Reads the chosen photo and fills the form in from the packaging.
  ///
  /// Everything it writes is an ordinary controller value the owner can edit or
  /// clear. Price is never touched — the server does not draft one.
  Future<void> _readPacket(List<CategoryData> categories) async {
    final image = _mainProductImage;
    if (image == null || _readingPacket) return;

    setState(() {
      _readingPacket = true;
      _draftError = null;
    });

    try {
      final bytes = kIsWeb
          ? await CloudinaryService.compressImageUsingUnit8List(
              await image.readAsBytes())
          : await CloudinaryService.compressImageUsingPath(image.path);

      final draft = await ApiService.draftProductFromImage(imageBytes: bytes);
      if (!mounted) return;

      // Only fill a field the owner hasn't already typed into, so re-reading a
      // photo never overwrites their own correction.
      void fill(String key, String value) {
        final controller = _formControllers[key];
        if (controller != null && controller.text.trim().isEmpty) {
          controller.text = value;
        }
      }

      fill('name', draft.name);
      fill('brand', draft.brand);
      fill('shortDescription', draft.shortDescription);
      fill('completeDescription', draft.completeDescription);

      final match = draft.categoryId == null
          ? null
          : categories.where((c) => c.id == draft.categoryId).firstOrNull;
      if (match != null && _selectedCategory == null) {
        _changeSelectedCategory(match);
      }

      setState(() => _draft = draft);
    } catch (e) {
      if (!mounted) return;
      setState(() => _draftError =
          e is CustomException ? e.message : 'Could not read that photo.');
    } finally {
      if (mounted) setState(() => _readingPacket = false);
    }
  }

  /// The assistant's offer, its progress, and what it wants checked.
  Widget _assistantPanel(List<CategoryData> categories) {
    final draft = _draft;
    final flagged = draft?.needsAttention ?? const <String>[];

    return CrossFade(
      state: (_readingPacket, draft != null, _draftError),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draft == null)
            PressableScale(
              onTap: _readingPacket ? null : () => _readPacket(categories),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  // The one highest-intent action on this screen.
                  color: _readingPacket ? AppColors.limeSurface : AppColors.lime,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Center(
                  child: _readingPacket
                      ? Text('Reading the packet…',
                          style: AppTextStyles.buttonText
                              .copyWith(color: AppColors.textOnLime))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 18, color: AppColors.textOnLime),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Fill this in from the photo',
                                style: AppTextStyles.buttonText
                                    .copyWith(color: AppColors.textOnLime)),
                          ],
                        ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.limeSurface,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flagged.isEmpty
                        ? 'Filled in from the photo — check it and add the price'
                        : 'Filled in from the photo — please check these',
                    style: AppTextStyles.labelLarge,
                  ),
                  if (flagged.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      flagged.map(_fieldLabel).join(' · '),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'The price is never filled in for you.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          if (_draftError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$_draftError You can still fill the form in yourself.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  /// Field key to the label the owner actually saw.
  String _fieldLabel(String key) {
    if (key == 'categoryId') return 'Category';
    return ProductConstants.formFields
            .where((f) => f.key == key)
            .firstOrNull
            ?.label ??
        key;
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
              ,
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
          }),
        if (enumFields.isNotEmpty)
          ...enumFields.entries
              .map(
                (MapEntry<String, List<String>> e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    initialValue: null, //categories[0].name,
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
                              .enumAttributes[e.key] = value
                          : _canHaveSpecificAttributes
                              .enumAttributes[e.key] = value;
                      updatGenSpecCat(_mustHaveSpecificAttributes,
                          _canHaveSpecificAttributes);
                    },
                    decoration: InputDecoration(
                        labelText:
                            'Select a ${e.key} ${type == AttributesType.must ? '**' : ''}'),
                  ),
                ),
              )
              ,
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
            return LoadingWidgets.spinKitFading(deviceWidth);
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
                  Text('Fields marked * are required',
                      style: AppTextStyles.caption),
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
                        : SizedBox(
                            height: 200.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: kIsWeb
                                  ? Image.network(_mainProductImage!.path)
                                  : Image.file(File(_mainProductImage!.path)),
                            ),
                          ),
                  ),
                  // Offered once there is a photo to read, since that photo is
                  // the whole input.
                  if (_mainProductImage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _assistantPanel(categories),
                  ],
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
                        ..._moreProductImages
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
                            ,
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ..._formFields.map((field) {
                    return Column(
                      children: [
                        TextFormField(
                          //move to next field
                          textInputAction: TextInputAction.next,
                          controller: _formControllers[field.key],
                          decoration: FormHandler.inputDec(
                            field.required ? '${field.label} *' : field.label,
                          ).copyWith(helperText: field.hint),
                          keyboardType: switch (field.kind) {
                            ProductFieldKind.rupees =>
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                            ProductFieldKind.whole => TextInputType.number,
                            ProductFieldKind.text => null,
                          },
                          inputFormatters: switch (field.kind) {
                            // A price needs its decimal point; a count doesn't.
                            ProductFieldKind.rupees => [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]')),
                              ],
                            ProductFieldKind.whole => [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ProductFieldKind.text => null,
                          },
                          // Optional fields carry no validator at all, so a
                          // shopkeeper can leave brand, long description and
                          // item code blank.
                          validator: !field.required
                              ? null
                              : switch (field.kind) {
                                  ProductFieldKind.rupees =>
                                    FormHandler.rupeeValidator,
                                  ProductFieldKind.whole =>
                                    FormHandler.wholeNumberValidator,
                                  ProductFieldKind.text =>
                                    FormHandler.stringValidator,
                                },
                        ),
                        SizedBox(
                          height: 20,
                        )
                      ],
                    );
                  }),
                  DropdownButtonFormField<CategoryData?>(
                    initialValue: null, //categories[0].name,
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
                      log(_generalSpecificCategory.toString());
                      if (_formKey.currentState!.validate()) {
                        if (_mainProductImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please select a main image'),
                            ),
                          );
                          return;
                        }
                        final List<Object> moreImages = [];
                        for (final element in _moreProductImages) {
                          moreImages.add(kIsWeb
                              ? await element.readAsBytes()
                              : element.path);
                        }
                        final List<Object> imageObjects = [
                          kIsWeb
                              ? await _mainProductImage!.readAsBytes()
                              : _mainProductImage!.path,
                          ...moreImages
                        ];
                        if (!context.mounted) return;
                        context.read<ShopBloc>().add(UploadProductEvent(
                            product: Product(
                              name: _formControllers['name']!.text.trim(),
                              brand: _formControllers['brand']!.text.trim(),
                              shortDescription:
                                  _formControllers['shortDescription']!
                                      .text
                                      .trim(),
                              images: [], //will get updated before uploading the product to db
                              // Rupees on screen, paise on the wire. Mirrors
                              // the inventory edit sheet.
                              price: FormHandler.rupeesToPaise(
                                  _formControllers['price']!.text),
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
                              // The server identifies a category by id; the
                              // nested object it used to receive carried only
                              // a name.
                              categoryId: _selectedCategory?.id,
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
