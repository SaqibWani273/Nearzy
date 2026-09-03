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
import 'presentation/common/widgets/shimmer_loading.dart';
import 'presentation/features/customer/customer_home_page.dart';
import 'presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';
import 'presentation/features/onboarding/view/onboarding_screen.dart';
import 'presentation/features/shop/product_upload/view_model/shop_bloc.dart';
import 'constants/bottom_navbar_items.dart';
import 'presentation/features/admin/admin_home_page.dart';
import 'presentation/features/shop/shop_authentication/view_model/shop_auth_bloc.dart';
import 'services/api_service.dart';
import 'services/session_manager.dart';
import 'theme/app_colors.dart';
import 'theme/theme.dart';
import 'utils/secure_storage.dart';

Future<void> main() async {
  WidgetsBinding wb = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: wb);
  // Saved accounts have to be readable before the first profile fetch, since
  // that fetch is what decides which home screen the app opens on.
  await SessionManager.instance.restore();
  UserModel? userModel = await mainAsyncTasks();
  String? hasSeenOnboarding =
      await SecureStorage.getData(key: 'has_seen_onboarding');
  runApp(MyApp(
    userModel: userModel,
    hasSeenOnboarding: hasSeenOnboarding == 'true',
  ));
  FlutterNativeSplash.remove();
}

class MyApp extends StatefulWidget {
  final UserModel? userModel;
  final bool hasSeenOnboarding;

  const MyApp({
    super.key,
    required this.userModel,
    required this.hasSeenOnboarding,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Surfaces session messages ("you were signed out") without needing a
  /// Scaffold in scope — the tree is being rebuilt when they arrive.
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  late UserModel? _userModel = widget.userModel;

  /// Bumped on every identity change. It keys the whole app below
  /// [MaterialApp], which is what tears down the previous account's
  /// repositories, blocs and navigation stack — none of a shopper's cart may
  /// survive into the shop account that replaces it.
  int _generation = 0;

  bool _switching = false;
  StreamSubscription<SessionEvent>? _sessionEvents;

  @override
  void initState() {
    super.initState();
    _sessionEvents = SessionManager.instance.events.listen(_onSessionEvent);
  }

  @override
  void dispose() {
    _sessionEvents?.cancel();
    super.dispose();
  }

  Future<void> _onSessionEvent(SessionEvent event) async {
    // A rotated token changes nothing the user can see, and rebuilding on it
    // would drop whatever screen they were on mid-scroll.
    if (event.change == SessionChange.refreshed) return;

    if (event.message != null) {
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(event.message!)));
    }

    setState(() => _switching = true);
    // Re-read the profile as whoever is now active; null simply means nobody
    // is, and the app falls back to browsing as a guest.
    final model = await ApiService.getUserModel();
    if (!mounted) return;
    setState(() {
      _userModel = model;
      _switching = false;
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userModel = _userModel;

    Customer? customer;
    ShopModel1? shopModel;
    if (userModel is Customer || userModel == null) {
      customer = userModel as Customer?;
    } else if (userModel is ShopModel1) {
      shopModel = userModel;
    }

    // An admin has no profile model: `/user/me` only builds one for customers
    // and shops, so `getUserModel` returns null for them and they fell through
    // to the customer home — leaving AdminHomePage unreachable from anywhere in
    // the app. The session's own role is the authority here.
    final isAdmin = SessionManager.instance.active?.role == Roles.ROLE_ADMIN;

    Widget homeScreen;
    if (_switching) {
      homeScreen = const _SwitchingScreen();
    } else if (isAdmin) {
      homeScreen = const AdminHomePage();
    } else if (userModel == null && !widget.hasSeenOnboarding) {
      homeScreen = const OnboardingScreen();
    } else if (userModel is Customer || userModel == null) {
      homeScreen = const CustomerHomePage();
    } else if (userModel is ShopModel1) {
      homeScreen = const ShopHomePage();
    } else {
      homeScreen = const NoInternetScreen();
    }

    return MaterialApp(
      title: 'Nearzy',
      theme: nearzyTheme,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      home: MultiRepositoryProvider(
        // Keyed on the generation so a switch builds fresh repositories rather
        // than handing the next account the previous one's cached state.
        key: ValueKey(_generation),
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
          // A Navigator per generation: pushed routes belonged to the account
          // being left, so they must not outlive it.
          child: Navigator(
            // The switching flag is part of the key on purpose: a Navigator
            // does not rebuild an already-pushed route, so the shimmer only
            // appears if the Navigator itself is replaced.
            key: ValueKey('nav-$_generation-$_switching'),
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (_) => homeScreen,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown for the moment between picking an account and its profile arriving.
class _SwitchingScreen extends StatelessWidget {
  const _SwitchingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: ShimmerLoading.listRows(count: 5, height: 72),
        ),
      ),
    );
  }
}
