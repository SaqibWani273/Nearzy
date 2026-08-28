import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
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
  final _formKey = GlobalKey<FormState>();
  String _email = "";
  String _password = "";
  String _username = "";

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header Info
            Text(
              currentForm == FormType.login
                  ? 'Welcome Back'
                  : currentForm == FormType.register
                      ? 'Create Account'
                      : 'Reset Password',
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: 6),
            Text(
              currentForm == FormType.login
                  ? 'Sign in to access your ${widget.userType == UserType.customer ? 'account' : 'store'}'
                  : currentForm == FormType.register
                      ? 'Join Nearzy and discover local products'
                      : 'Enter your registered email below',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 32),

            if (currentForm == FormType.register) ...[
              Text(
                widget.userType == UserType.customer
                    ? "Full Name"
                    : "Shop / Business Name",
                style: AppTextStyles.inputLabel,
              ),
              const SizedBox(height: 6),
              TextFormField(
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: widget.userType == UserType.customer
                      ? "e.g. Rahul Sharma"
                      : "e.g. Royal Kashmiri Crafts",
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || !value.isValidUsername()) {
                    return 'Please enter a valid name';
                  }
                  return null;
                },
                onSaved: (value) => _username = value!,
              ),
              const SizedBox(height: 20),
            ],

            Text("Email Address", style: AppTextStyles.inputLabel),
            const SizedBox(height: 6),
            TextFormField(
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || !value.isValidEmail()) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              onSaved: (value) => _email = value!,
            ),
            const SizedBox(height: 20),

            if (currentForm == FormType.register ||
                currentForm == FormType.login) ...[
              Text("Password", style: AppTextStyles.inputLabel),
              const SizedBox(height: 6),
              TextFormField(
                textInputAction: currentForm == FormType.register
                    ? TextInputAction.next
                    : TextInputAction.done,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) {
                  if (currentForm != FormType.register) return null;
                  if (value == null || !value.isValidPassword()) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onSaved: (value) => _password = value!,
              ),
              if (currentForm == FormType.login)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() => currentForm = FormType.forgotpassword);
                    },
                    child: Text('Forgot Password?', style: AppTextStyles.link),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            if (currentForm == FormType.register) ...[
              Text("Confirm Password", style: AppTextStyles.inputLabel),
              const SizedBox(height: 6),
              TextFormField(
                textInputAction: TextInputAction.done,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  return null;
                },
                onSaved: (value) => _password = value!,
              ),
              const SizedBox(height: 24),
            ],

            if (widget.userType == UserType.shop &&
                currentForm == FormType.register)
              OtherShopDetailsWidget(key: _childKey),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    if (await ApiService.emailExists(_email) == true &&
                        currentForm == FormType.register) {
                      Utils.showScaffoldMessage(
                          message: "Email already registered",
                          context: context);
                      return;
                    }
                    if (await ApiService.usernameExists(_username) == true &&
                        currentForm == FormType.register) {
                      Utils.showScaffoldMessage(
                          message: "Username already taken", context: context);
                      return;
                    }

                    if (currentForm == FormType.forgotpassword) {
                      Utils.showScaffoldMessage(
                          message: "Password reset link sent",
                          context: context);
                    } else if (currentForm == FormType.register) {
                      if (widget.userType == UserType.shop) {
                        if (!_childKey.currentState!.formKey.currentState!
                            .validate()) return;
                        final allImagesFilled =
                            _childKey.currentState?.checkImagesFilled();
                        if (allImagesFilled != true) return;
                        if (context.read<ShopDataRepository>().locationInfo ==
                            null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Please select a location")),
                          );
                          return;
                        }
                        _childKey.currentState!.formKey.currentState!.save();
                      }

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
                      ? 'Sign In'
                      : currentForm == FormType.forgotpassword
                          ? 'Send Reset Link'
                          : 'Create Account',
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: currentForm == FormType.login ||
                              currentForm == FormType.forgotpassword
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextSpan(
                      text: currentForm == FormType.login ||
                              currentForm == FormType.forgotpassword
                          ? 'Sign Up'
                          : 'Sign In',
                      style: AppTextStyles.link,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          setState(() {
                            currentForm = currentForm == FormType.login
                                ? FormType.register
                                : FormType.login;
                          });
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtherShopDetailsWidget extends StatefulWidget {
  const OtherShopDetailsWidget({super.key});

  @override
  State<OtherShopDetailsWidget> createState() => _OtherShopDetailsWidgetState();
}

class _OtherShopDetailsWidgetState extends State<OtherShopDetailsWidget> {
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
  final ImagePicker _picker = ImagePicker();
  late final List<String> categories;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool checkImagesFilled() {
    if (_shopPic == null ||
        _ownerPic == null ||
        _pancardPic == null ||
        _ownerIdPic == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload all required shop and owner images'),
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

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32),
          Text('Shop Details', style: AppTextStyles.heading3),
          const SizedBox(height: 16),

          ImageUploadField(
            picker: _picker,
            onUpload: (imgObject) => _shopPic = imgObject,
            hintText: "Shop Front Photo",
            imageHeight: deviceHeight * 0.2,
            placeholderHeight: deviceHeight * 0.1,
          ),
          const SizedBox(height: 16),

          Text("About Your Shop", style: AppTextStyles.inputLabel),
          const SizedBox(height: 6),
          TextFormField(
            textInputAction: TextInputAction.next,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Brief summary of what your shop specializes in',
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Description is required' : null,
            onSaved: (value) => _shopDescription = value,
          ),
          const SizedBox(height: 16),

          const ShopLocationWidget(),
          const SizedBox(height: 16),

          Text("Shop Address", style: AppTextStyles.inputLabel),
          const SizedBox(height: 6),
          TextFormField(
            textInputAction: TextInputAction.next,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Shop No., Street, Area, City, Pincode',
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Address is required' : null,
            onSaved: (value) => _address = value,
          ),
          const SizedBox(height: 16),

          Text("Business License No.", style: AppTextStyles.inputLabel),
          const SizedBox(height: 6),
          TextFormField(
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'GSTIN / Trade License / Shop Registration',
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'License number is required' : null,
            onSaved: (value) => _businessLicense = value,
          ),
          const SizedBox(height: 16),

          ImageUploadField(
            picker: _picker,
            onUpload: (imgObject) => _ownerPic = imgObject,
            hintText: "Owner Photograph",
            imageHeight: deviceHeight * 0.2,
            placeholderHeight: deviceHeight * 0.1,
          ),
          const SizedBox(height: 16),

          Text("Owner Full Name", style: AppTextStyles.inputLabel),
          const SizedBox(height: 6),
          TextFormField(
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'As per official ID proof',
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Owner name is required' : null,
            onSaved: (value) => _ownerName = value,
          ),
          const SizedBox(height: 16),

          ImageUploadField(
            picker: _picker,
            onUpload: (imgObject) => _ownerIdPic = imgObject,
            hintText: "Govt ID Proof (Aadhaar / Voter ID)",
            imageHeight: deviceHeight * 0.2,
            placeholderHeight: deviceHeight * 0.1,
          ),
          const SizedBox(height: 16),

          Text("Mobile Number", style: AppTextStyles.inputLabel),
          const SizedBox(height: 6),
          TextFormField(
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '10-digit mobile number',
              prefixText: '+91 ',
            ),
            validator: (value) =>
                value != null && value.length == 10 ? null : 'Invalid 10-digit number',
            onSaved: (value) {
              if (value != null) _phoneNumber = int.tryParse(value);
            },
          ),
          const SizedBox(height: 16),

          ImageUploadField(
            picker: _picker,
            onUpload: (imgObject) => _pancardPic = imgObject,
            hintText: "PAN Card Document",
            imageHeight: deviceHeight * 0.2,
            placeholderHeight: deviceHeight * 0.1,
          ),
          const SizedBox(height: 20),

          Text("Select Product Categories", style: AppTextStyles.heading4),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final isSelected = selectedCategories.contains(cat);
              return FilterChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedCategories.add(cat);
                    } else {
                      selectedCategories.remove(cat);
                    }
                  });
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
