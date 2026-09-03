import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/constants/bottom_navbar_items.dart';
import '../../common/widgets/animated_bottom_nav.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import 'product_upload/view_model/shop_bloc.dart';
import 'shop_authentication/view_model/shop_auth_bloc.dart';

class ShopHomePage extends StatefulWidget {
  const ShopHomePage({super.key});

  @override
  State<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  int _currentIndex = 0; // Start on the triage dashboard
  late final PageController _pageController;

  void _changeIndex(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppSpacing.durationNormal,
      curve: AppSpacing.curveDefault,
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    context.read<ShopBloc>().add(ShopLoadProductsEvent());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      // Signing out swaps the whole shell — to the next saved account, or to
      // guest browsing — so there is nothing to navigate to from here.
      body: BlocBuilder<ShopAuthBloc, ShopAuthState>(
        builder: (context, state) {
          if (state is ShopAuthLoadingState) {
            return ShimmerLoading.productGrid();
          }
          return PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: shopMainScreens(_changeIndex),
          );
        },
      ),
      bottomNavigationBar: NearzyBottomNav(
        currentIndex: _currentIndex,
        onTap: _changeIndex,
        items: shopNavItems,
      ),
    );
  }
}
