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
import '../../../theme/app_spacing.dart';
import 'authentication/view_model/customer_auth_bloc.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _currentIndex = 2; // Start on Home
  final int _currentDrawerItemIndex = 0;
  Customer? customer;
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
    customer = context.read<CustomerDataRepository>().customer;
    _pageController = PageController(initialPage: _currentIndex);
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
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: AppBarWidget(),
          ),
          drawer: DrawerWidget(
            currentIndex: _currentDrawerItemIndex,
            homePageContext: context,
          ),
          body: SafeArea(
            child: RefreshIndicator.adaptive(
              color: AppColors.primary,
              onRefresh: () async {
                context
                    .read<CustomerAuthBloc>()
                    .add(CustomerAuthVerificationEvent());
                context
                    .read<CustomerDataBloc>()
                    .add(CustomerDataLoadProductsEvent());
              },
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: customerMainScreens,
              ),
            ),
          ),
          bottomNavigationBar: NearzyBottomNav(
            currentIndex: _currentIndex,
            onTap: _changeIndex,
            items: customerNavItems,
          ),
        );
      },
    );
  }
}
