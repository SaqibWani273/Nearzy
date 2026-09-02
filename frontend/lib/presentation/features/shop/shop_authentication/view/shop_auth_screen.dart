import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/data/repositories/shop/shop_data_repository.dart';
import '../../../../../data/models/shop_model/shop_model1.dart';
import '../../../../../data/models/basic_user_model/basic_user_model.dart';
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
  @override
  void initState() {
    context.read<ShopAuthBloc>().add(ShopAuthInitialEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      // No navigation on success: signing in publishes a session event and
      // the app shell rebuilds onto the shop home itself. Pushing here as well
      // raced that rebuild and could strand a dead route on top of it.
      body:
          BlocConsumer<ShopAuthBloc, ShopAuthState>(listener: (context, state) {
      }, builder: (context, state) {
        if (state is ShopAuthLoadingState) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (state is ShopAuthEmailSentState) {
          return EmailSentWidget(
            onPressed: () =>
                context.read<ShopAuthBloc>().add(ShopAuthInitialEvent()),
          );
        }
        //do nothing here for location error
        if (state is ShopAuthErrorState &&
            !state.error.errorType.name.toLowerCase().contains("location")) {
          return Center(
              child: ErrorScreen(
            customException: state.error,
            onTryAgainPressed: () =>
                context.read<ShopAuthBloc>().add(ShopAuthInitialEvent()),
          ));
        }

        return FormWidget(
          userType: UserType.shop,
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
                    locationInfo:
                        context.read<ShopDataRepository>().locationInfo!,
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
          loginCallback: ({required email, required password}) => context
              .read<ShopAuthBloc>()
              .add(ShopAuthLoginEvent(email, password)),
        );
      }),
    );
  }
}
