import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '/data/models/shop_model/shop_model1.dart';
import '/data/repositories/shop/shop_data_repository.dart';
import '/presentation/common/screens/no_internet_screen.dart';
import '/presentation/features/customer/authentication/view_model/customer_auth_bloc.dart';
import '/presentation/features/shop/shop_home_page.dart';
import '/utils/main_async_tasks.dart';
import 'data/models/customer.dart';
import 'data/repositories/customer/customer_data_repository.dart';
import 'presentation/features/customer/customer_home_page.dart';
import 'presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';
import 'presentation/features/onboarding/view/onboarding_screen.dart';
import 'presentation/features/shop/product_upload/view_model/shop_bloc.dart';
import 'presentation/features/shop/shop_authentication/view_model/shop_auth_bloc.dart';
import 'theme/theme.dart';
import 'utils/secure_storage.dart';

Future<void> main() async {
  WidgetsBinding wb = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: wb);
  UserModel? userModel = await mainAsyncTasks();
  String? hasSeenOnboarding =
      await SecureStorage.getData(key: 'has_seen_onboarding');
  runApp(MyApp(
    userModel: userModel,
    hasSeenOnboarding: hasSeenOnboarding == 'true',
  ));
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  final UserModel? userModel;
  final bool hasSeenOnboarding;

  const MyApp({
    super.key,
    required this.userModel,
    required this.hasSeenOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    Customer? customer;
    ShopModel1? shopModel;
    if (userModel is Customer || userModel == null) {
      customer = userModel as Customer?;
    } else if (userModel is ShopModel1) {
      shopModel = userModel as ShopModel1;
    }

    Widget homeScreen;
    if (userModel == null && !hasSeenOnboarding) {
      homeScreen = const OnboardingScreen();
    } else if (userModel is Customer || userModel == null) {
      homeScreen = const CustomerHomePage();
    } else if (userModel is ShopModel1) {
      homeScreen = const ShopHomePage();
    } else {
      homeScreen = const NoInternetScreen();
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => CustomerDataRepository(customer: customer),
        ),
        RepositoryProvider(
          create: (context) => ShopDataRepository(shopModel: shopModel),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => CustomerAuthBloc(
              customerDataRepository:
                  RepositoryProvider.of<CustomerDataRepository>(context),
            ),
          ),
          BlocProvider(
            create: (context) => CustomerDataBloc(
              customerDataRepository:
                  RepositoryProvider.of<CustomerDataRepository>(context),
            ),
          ),
          BlocProvider(
            create: (context) => ShopAuthBloc(
              shopDataRepository:
                  RepositoryProvider.of<ShopDataRepository>(context),
            ),
          ),
          BlocProvider(
            create: (context) => ShopBloc(
              shopDataRepository:
                  RepositoryProvider.of<ShopDataRepository>(context),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Nearzy',
          theme: nearzyTheme,
          debugShowCheckedModeBanner: false,
          home: homeScreen,
        ),
      ),
    );
  }
}
