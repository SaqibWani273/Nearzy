import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/presentation/features/customer/appbar_widget.dart';
import '/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/customer/customer_data_repository.dart';
import '../../common/widgets/animated_bottom_nav.dart';
import '../../common/widgets/drawer_widget.dart';
import '../../../constants/bottom_navbar_items.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';

/// Lets descendants — the drawer in particular — switch the shell's tab
/// without reaching into private State.
///
/// The drawer's "Cart", "Categories" and "Profile" entries are the same
/// destinations as the bottom nav, so they must move the existing tab rather
/// than push a duplicate screen on top of it.
class HomeTabScope extends InheritedWidget {
  const HomeTabScope({super.key, required this.goToTab, required super.child});

  final void Function(int index) goToTab;

  /// Tab positions, mirroring `customerMainScreens`.
  static const int explore = 0;
  static const int categories = 1;
  static const int home = 2;
  static const int cart = 3;
  static const int profile = 4;

  static HomeTabScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeTabScope>();

  @override
  bool updateShouldNotify(HomeTabScope oldWidget) => false;
}

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _currentIndex = 2; // Start on Home
  Customer? customer;
  late final PageController _pageController;

  void _changeIndex(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: Motion.base,
      curve: Motion.emphasis,
    );
  }

  /// Decorates the Cart destination with a live item count.
  List<NearzyNavItem> _navItems(BuildContext context) {
    final count =
        context.read<CustomerDataRepository>().customer?.cartItems?.length ?? 0;
    return [
      for (final item in customerNavItems)
        item.label == 'Cart' ? item.copyWith(badgeCount: count) : item,
    ];
  }

  @override
  void initState() {
    super.initState();
    final repository = context.read<CustomerDataRepository>();
    customer = repository.customer;
    _pageController = PageController(initialPage: _currentIndex);
    // Saved items and recent searches live on the device; pull them in once
    // the shell mounts rather than blocking app start on them.
    repository.restorePreferences();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerDataBloc, CustomerDataState>(
      builder: (context, state) {
        return HomeTabScope(
          goToTab: _changeIndex,
          // Back from a tab returns to Home rather than closing the app. The
          // tabs are a PageView, not routes, so nothing else would have
          // caught the gesture — three taps into Categories, back quit.
          //
          // On Home itself the pop is allowed through, which is where
          // Android's own "back leaves the app" behaviour belongs.
          child: PopScope(
            canPop: _currentIndex == HomeTabScope.home,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _changeIndex(HomeTabScope.home);
            },
            child: Scaffold(
              backgroundColor: AppColors.paper,
              // The nav bar floats over the content, so the body has to
              // extend behind it. Screens reserve AppSpacing.bottomNavInset
              // at their tail.
              extendBody: true,
              appBar: const PreferredSize(
                preferredSize: Size.fromHeight(64),
                child: AppBarWidget(),
              ),
              drawer: DrawerWidget(
                currentTab: _currentIndex,
                homePageContext: context,
              ),
              body: SafeArea(
                bottom: false,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: customerMainScreens,
                ),
              ),
              bottomNavigationBar: NearzyBottomNav(
                currentIndex: _currentIndex,
                onTap: _changeIndex,
                items: _navItems(context),
              ),
            ),
          ),
        );
      },
    );
  }
}
