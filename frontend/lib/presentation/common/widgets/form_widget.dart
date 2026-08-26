import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '/data/repositories/shop/shop_data_repository.dart';
import '/presentation/common/widgets/image_upload_field.dart';
import '/presentation/common/widgets/location_widget.dart';
import '/utils/utils.dart';
import '../../../services/api_service.dart';
import '/utils/extensions/form_validation.dart';

enum FormType { login, register, forgotpassword }

enum UserType { customer, shop }

class FormWidget extends StatefulWidget {
  final UserType userType;
  final void Function(
    Map<String, dynamic>? otherShopDetails, {
    required String email,
    required String password,
    required String username,
  }) registerCallback;
  final void Function({required String email, required String password})
      loginCallback;
  const FormWidget({
    super.key,
    required this.registerCallback,
    required this.loginCallback,
    required this.userType,
  });

  @override
  State<FormWidget> createState() => _FormWidgetState();
}

class _FormWidgetState extends State<FormWidget> {
  final GlobalKey<_OtherShopDetailsWidgetState> _childKey =
      GlobalKey<_OtherShopDetailsWidgetState>();
  FormType currentForm = FormType.login;
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  String _email = "";
  String _password = "";
  String _username = "";
  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Container(
          //only for large screens
          margin: deviceHeight > 700
              ? EdgeInsets.only(top: deviceHeight * 0.1)
              : null,
          padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (currentForm == FormType.register)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userType == UserType.customer
                        ? "Username"
                        : "Shop Name"),
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        errorStyle: TextStyle(fontSize: 10.0),
                        labelText: widget.userType == UserType.customer
                            ? "Username"
                            : "Shop Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || !value.isValidUsername()) {
                          return 'Please enter name in proper-format';
                        }
                        return null;
                      },
                      onSaved: (value) => _username = value!,
                    ),
                  ],
                ),
              SizedBox(height: 20.0),
              Text("Email"),
              TextFormField(
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: currentForm == FormType.forgotpassword
                      ? 'Enter Registered Email'
                      : 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || !value.isValidEmail()) {
                    return 'Please enter valid email address';
                  }

                  return null;
                },
                onSaved: (value) => _email = value!, // Update _email on save
              ),
              if (currentForm == FormType.register ||
                  currentForm == FormType.login)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Password"),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      obscureText: true,

                      decoration: InputDecoration(
                        labelText: 'Enter Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (currentForm != FormType.register) {
                          return null;
                        }
                        if (value == null || !value.isValidPassword()) {
                          return 'Please enter strong password';
                        }
                        return null;
                      },
                      onSaved: (value) =>
                          _password = value!, // Update _password on save
                    ),
                    if (currentForm == FormType.login)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: RichText(
                          text: TextSpan(
                              text: "Forgot Password?",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(color: Colors.blue),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  setState(() {
                                    currentForm = FormType.forgotpassword;
                                  });
                                }),
                        ),
                      ),
                  ]),
                  SizedBox(height: 20.0),
                ]),
              if (currentForm == FormType.register)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(height: 20.0),
                  Text("Confirm Password"),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    obscureText: true,

                    decoration: InputDecoration(
                      labelText: 'Enter same Password again',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter same password';
                      }
                      return null;
                    },
                    onSaved: (value) =>
                        _password = value!, // Update _password on save
                  ),
                  SizedBox(height: 20.0),
                ]),
              if (widget.userType == UserType.shop &&
                  currentForm == FormType.register)
                OtherShopDetailsWidget(
                  key: _childKey,
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(deviceWidth, 50),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    if (await ApiService.emailExists(_email) == true) {
                      Utils.showScaffoldMessage(
                          message: "Email already exists", context: context);
                      return;
                    }
                    if (await ApiService.usernameExists(_username) == true) {
                      Utils.showScaffoldMessage(
                          message: "Username already exists", context: context);
                      return;
                    }

                    if (currentForm == FormType.forgotpassword) {
                    } else if (currentForm == FormType.register) {
                      if (widget.userType == UserType.shop) {
                        //other shop details validation
                        if (!_childKey.currentState!.formKey.currentState!
                            .validate()) return;
                        //images in other shop details
                        final allImagesFilled =
                            _childKey.currentState?.checkImagesFilled();
                        if (allImagesFilled != true) {
                          return;
                        }
                        if (context.read<ShopDataRepository>().locationInfo ==
                            null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Please provide proper location")));
                          return;
                        }
                        //save other shop details form
                        _childKey.currentState!.formKey.currentState!.save();
                      }
                      //register
                      widget.registerCallback(
                        widget.userType == UserType.customer
                            ? {}
                            : _childKey.currentState!.getOtherShopDetails(),
                        email: _email,
                        password: _password,
                        username: _username,
                      );
                    } else {
                      widget.loginCallback(email: _email, password: _password);
                    }
                  }
                },
                child: Text(
                  currentForm == FormType.login
                      ? 'Login'
                      : currentForm == FormType.forgotpassword
                          ? 'Submit'
                          : 'Register',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(
                height: 40.0,
              ),
              RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(children: [
                    TextSpan(
                      text: currentForm == FormType.login ||
                              currentForm == FormType.forgotpassword
                          ? 'Don\'t have an account? '
                          : "Already have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                      // style: defaultStyle,
                    ),
                    TextSpan(
                        text: currentForm == FormType.login ||
                                currentForm == FormType.forgotpassword
                            ? 'Register Here'
                            : 'Login Here',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            setState(() {
                              currentForm = currentForm == FormType.login
                                  ? FormType.register
                                  : FormType.login;
                            });
                          }),
                  ])),
            ],
          ),
        ),
      ),
    );
  }
}

class OtherShopDetailsWidget extends StatefulWidget {
  const OtherShopDetailsWidget({
    super.key,
  });

  @override
  State<OtherShopDetailsWidget> createState() => _OtherShopDetailsWidgetState();
}

class _OtherShopDetailsWidgetState extends State<OtherShopDetailsWidget> {
  //pictures could be file path(i.e. String) for Web or Unit8List for mobile
  Object? _shopPic;
  Object? _ownerPic;
  Object? _pancardPic;
  Object? _ownerIdPic;
  String? _businessLicense;
  String? _address;
  String? _ownerName;
  int? _phoneNumber;
  String? _shopDescription;
  List<String> selectedCategories = [];
  ImagePicker _picker = ImagePicker();
  late final List<String> categories;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool checkImagesFilled() {
    if (_shopPic == null ||
        _ownerPic == null ||
        _pancardPic == null ||
        _ownerIdPic == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload all images'),
      ));
      return false;
    }
    return true;
  }

  Map<String, dynamic> getOtherShopDetails() {
    return {
      'ownerName': _ownerName!,
      'shopPicUrl': _shopPic,
      'ownerPicUrl': _ownerPic,
      'pancardPicUrl': _pancardPic,
      'ownerIdPicUrl': _ownerIdPic,
      'businessLicense': _businessLicense!,
      'phoneNumber': _phoneNumber!.toString(),
      'categories': selectedCategories,
      'address': _address!,
      'description': _shopDescription!,
    };
  }

  @override
  void initState() {
    categories = context
        .read<ShopDataRepository>()
        .categoriesData
        .map((e) => e.name)
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var deviceHeight = MediaQuery.of(context).size.height;

    var deviceWidth = MediaQuery.of(context).size.width;
    return Form(
        key: formKey,
        child: Column(
          children: [
            ImageUploadField(
              picker: _picker,
              onUpload: (imgObject) => _shopPic = imgObject,
              hintText: "Front Side of Shop",
              imageHeight: deviceHeight * 0.2,
              placeholderHeight: deviceHeight * 0.1,
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Breif About Your Shop"),
              TextFormField(
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Enter Short Breif About Your Shop',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter proper Breif About Your Shop';
                  }
                  return null;
                },
                onSaved: (value) => _shopDescription = value,
              ),
              SizedBox(height: 20.0),
            ]),
            //shop location
            ShopLocationWidget(),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Proper Shop Address"),
              TextFormField(
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText:
                      'E.g. Letpora,Pampore,Pulwama,Srinagar,Jammu & Kashmir',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter valid Business License Number';
                  }
                  return null;
                },
                onSaved: (value) => _address = value,
              ),
              SizedBox(height: 20.0),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Business License Number"),
              TextFormField(
                textInputAction: TextInputAction.next,

                decoration: InputDecoration(
                  labelText: 'Enter Proper Business License Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter valid Business License Number';
                  }
                  return null;
                },
                onSaved: (value) =>
                    _businessLicense = value, // Update _password on save
              ),
              SizedBox(height: 20.0),
            ]),
            ImageUploadField(
              picker: _picker,
              onUpload: (imgObject) => _ownerPic = imgObject,
              hintText: "Shop Owner Picture",
              imageHeight: deviceHeight * 0.2,
              placeholderHeight: deviceHeight * 0.1,
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Owner Name"),
              TextFormField(
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Registered Shop Owner Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Proper name ';
                  }
                  return null;
                },
                onSaved: (value) => _ownerName = value,
              ),
              SizedBox(height: 20.0),
            ]),
            ImageUploadField(
              picker: _picker,
              onUpload: (imgObject) => _ownerIdPic = imgObject,
              hintText: "Owner Id",
              imageHeight: deviceHeight * 0.2,
              placeholderHeight: deviceHeight * 0.1,
            ),
            SizedBox(height: 20.0),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Mobile Number"),
              TextFormField(
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Enter Proper Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter valid Mobile Number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    if (value != null && value.length == 10)
                      _phoneNumber =
                          int.tryParse(value); // Update _password on save
                  }),
              SizedBox(height: 20.0),
            ]),
            ImageUploadField(
              picker: _picker,
              onUpload: (imgObject) => _pancardPic = imgObject,
              hintText: "Pancard",
              imageHeight: deviceHeight * 0.2,
              placeholderHeight: deviceHeight * 0.1,
            ),

            //select
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select one or more Categories"),
                  GridView(
                    //noscroll

                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        mainAxisExtent: deviceHeight * 0.1,
                        crossAxisCount: deviceWidth > 700
                            ? 3
                            : deviceWidth < 250
                                ? 1
                                : 2,
                        mainAxisSpacing: 0.0),
                    children: categories.map((e) {
                      return SizedBox(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 0.0),
                          onChanged: (value) {
                            if (value == true) {
                              selectedCategories.add(e);
                            } else {
                              selectedCategories.remove(e);
                            }
                            setState(() {
                              selectedCategories = selectedCategories;
                            });
                          },
                          value: selectedCategories.contains(e),
                          title: Text(
                            e,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.0),
          ],
        ));
  }
}
