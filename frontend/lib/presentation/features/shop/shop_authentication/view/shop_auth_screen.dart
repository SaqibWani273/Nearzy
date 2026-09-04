import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/data/repositories/shop/shop_data_repository.dart';
import '../../../../../data/models/shop_model/shop_model1.dart';
import '../../../../../data/models/basic_user_model/basic_user_model.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../common/screens/error_screen.dart';
import '/presentation/common/widgets/email_sent_widget.dart';
import '/presentation/common/widgets/form_widget.dart';

import '../view_model/shop_auth_bloc.dart';

class ShopAuthScreen extends StatefulWidget {
  const ShopAuthScreen({super.key});

  @override
  State<ShopAuthScreen> createState() => _ShopAuthScreenState();
}

class _ShopAuthScreenState extends State<ShopAuthScreen> {
  /// The failure to show above the form. A wrong password used to replace the
  /// whole screen with an error page, which threw away every field the
  /// shopkeeper had filled in — including the eight images on the register
  /// form.
  String? _error;

  @override
  void initState() {
    context.read<ShopAuthBloc>().add(ShopAuthInitialEvent());
    super.initState();
  }

  /// A location failure is the one error that genuinely cannot be fixed from
  /// this form — it needs the OS permission dialog — so it keeps the
  /// full-screen treatment with its own retry.
  bool _isLocationError(ShopAuthState state) =>
      state is ShopAuthErrorState &&
      state.error.errorType.name.toLowerCase().contains('location');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(backgroundColor: AppColors.paper),
      // No navigation on success: signing in publishes a session event and
      // the app shell rebuilds onto the shop home itself. Pushing here as well
      // raced that rebuild and could strand a dead route on top of it.
      body: BlocConsumer<ShopAuthBloc, ShopAuthState>(
          listener: (context, state) {
        if (state is ShopAuthErrorState && !_isLocationError(state)) {
          setState(() => _error = state.error.message);
        } else if (state is ShopAuthLoadingState) {
          if (_error != null) setState(() => _error = null);
        }
      }, builder: (context, state) {
        if (state is ShopAuthEmailSentState) {
          return EmailSentWidget(
            onPressed: () =>
                context.read<ShopAuthBloc>().add(ShopAuthInitialEvent()),
          );
        }

        if (state is ShopAuthErrorState && _isLocationError(state)) {
          return Center(
              child: ErrorScreen(
            customException: state.error,
            onTryAgainPressed: () =>
                context.read<ShopAuthBloc>().add(ShopAuthInitialEvent()),
          ));
        }

        // The form stays mounted under the spinner. Replacing it with a bare
        // CircularProgressIndicator disposed every TextFormField, so a failed
        // sign-in came back to an empty form.
        return Stack(
          children: [
            _buildForm(context),
            if (state is ShopAuthLoadingState)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildForm(BuildContext context) {
    return FormWidget(
      userType: UserType.shop,
      errorMessage: _error,
      onDismissError: () {
        if (_error != null) setState(() => _error = null);
      },
      registerCallback: (
        moreShopDetails, {
        required email,
        required password,
        required username,
      }) =>
          context.read<ShopAuthBloc>().add(ShopAuthRegisterEvent(ShopModel1(
                user: BasicUserModel(
                  username: username,
                  password: password,
                  email: email,
                ),
                locationInfo: context.read<ShopDataRepository>().locationInfo!,
                businessLicense: moreShopDetails!['businessLicense']!,
                categories: moreShopDetails['categories']! as List<String>,
                shopPicUrl: moreShopDetails['shopPicUrl']!,
                description: moreShopDetails['description']!,
                ownerName: moreShopDetails['ownerName']!,
                ownerIdPicUrl: moreShopDetails['ownerIdPicUrl']!,
                pancardPicUrl: moreShopDetails['pancardPicUrl']!,
                phoneNumber: moreShopDetails['phoneNumber']!,
                ownerPicUrl: moreShopDetails['ownerPicUrl']!,
                address: moreShopDetails['address']!,
              ))),
      loginCallback: ({required email, required password}) =>
          context.read<ShopAuthBloc>().add(ShopAuthLoginEvent(email, password)),
    );
  }
}
