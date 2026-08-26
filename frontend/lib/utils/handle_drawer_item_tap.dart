import 'package:flutter/material.dart';
import '/constants/drawer_data.dart';

import '../presentation/features/shop/shop_authentication/view/shop_auth_screen.dart';

void handleDrawerItemTap({
  required DrawerItemsEnum enumValue,
  required BuildContext context,
  required BuildContext homepageContext,
}) {
  Navigator.of(context).pop();
  switch (enumValue) {
    case DrawerItemsEnum.home:
      break;
    case DrawerItemsEnum.favourites:
      break;
    case DrawerItemsEnum.specialOffers:
      break;
    case DrawerItemsEnum.categories:
      break;
    case DrawerItemsEnum.shop:
      break;
    case DrawerItemsEnum.yourOrders:
      break;
    case DrawerItemsEnum.cart:
      break;
    case DrawerItemsEnum.helpAndSupport:
      break;
    case DrawerItemsEnum.registerShop:
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ShopAuthScreen()));
      break;
    case DrawerItemsEnum.profile:
      break;
  }
}
