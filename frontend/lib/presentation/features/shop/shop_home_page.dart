import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/constants/bottom_navbar_items.dart';
import 'package:mca_project/presentation/common/widgets/loading_widgets.dart';
import 'product_upload/view/upload_product_screen.dart';
import '/presentation/features/shop/shop_authentication/view/shop_auth_screen.dart';

import 'product_upload/view_model/shop_bloc.dart';
import 'shop_authentication/view_model/shop_auth_bloc.dart';

class ShopHomePage extends StatefulWidget {
  const ShopHomePage({super.key});

  @override
  State<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  int currentIndex = 1;
  void changeIndex(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  void initState() {
    context.read<ShopBloc>().add(ShopLoadProductsEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: BlocConsumer<ShopAuthBloc, ShopAuthState>(
        listener: (context, state) {
          if (state is ShopAuthLoggedOutState) {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ShopAuthScreen()),
                (route) => false);
          }
        },
        builder: (context, state) {
          if (state is ShopAuthLoadingState) {
            return LoadingWidgets.SpinKitFading(deviceWidth);
          }
          return shopMainScreens[currentIndex];
        },
      ),
      bottomNavigationBar: CurvedNavigationBar(
        maxWidth: deviceWidth,
        index: 1,
        items: shopBottomNavbarItems
            .asMap()
            .entries
            .map((e) => Container(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  // height: deviceHeight * 0.05,

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(currentIndex == e.key
                          ? e.value.selectedIcon
                          : e.value.unselectedIcon),
                      Text(
                        e.value.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ))
            .toList(),
        onTap: (value) => {
          changeIndex(value),
        },
      ),
    );
  }
}
