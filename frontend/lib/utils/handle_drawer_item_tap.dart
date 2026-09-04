import 'package:flutter/material.dart';

import '../constants/drawer_data.dart';
import '../presentation/common/animations/nearzy_page_route.dart';
import '../presentation/features/customer/address/address_picker_sheet.dart';
import '../presentation/features/customer/authentication/view/customer_login.dart';
import '../presentation/features/customer/customer_home_page.dart';
import '../presentation/features/customer/offers/offers_screen.dart';
import '../presentation/features/customer/orders/view/customer_orders_screen.dart';
import '../presentation/features/customer/saved/saved_items_screen.dart';
import '../presentation/features/customer/support/help_screen.dart';
import '../presentation/features/shop/shop_authentication/view/shop_auth_screen.dart';

/// Routes a drawer selection.
///
/// Three rules keep this honest:
///
///   * The drawer already closes itself before calling this, so nothing here
///     may pop again — a second pop tears the home page off the stack and
///     leaves a blank screen behind it.
///   * Destinations that are also bottom-nav tabs switch the tab instead of
///     pushing a duplicate screen over it, so the nav bar keeps matching what
///     is on screen.
///   * Every case actually goes where its label says. "Your orders" used to
///     open the profile tab and stop there.
void handleDrawerItemTap({
  required DrawerItemsEnum enumValue,
  required BuildContext context,
  required BuildContext homepageContext,
}) {
  // Tab moves are driven through the home shell's scope. Resolved from the
  // home page's context because the drawer's own context is gone by now.
  void goToTab(int index) =>
      HomeTabScope.maybeOf(homepageContext)?.goToTab(index);

  switch (enumValue) {
    case DrawerItemsEnum.home:
      goToTab(HomeTabScope.home);
    case DrawerItemsEnum.exploreShops:
      goToTab(HomeTabScope.explore);
    case DrawerItemsEnum.categories:
      goToTab(HomeTabScope.categories);
    case DrawerItemsEnum.cart:
      goToTab(HomeTabScope.cart);
    case DrawerItemsEnum.profile:
      goToTab(HomeTabScope.profile);

    case DrawerItemsEnum.yourOrders:
      homepageContext.pushScreen(() => const CustomerOrdersScreen());
    case DrawerItemsEnum.savedItems:
      homepageContext.pushScreen(() => const SavedItemsScreen());
    case DrawerItemsEnum.specialOffers:
      homepageContext.pushScreen(() => const OffersScreen());
    case DrawerItemsEnum.helpAndSupport:
      homepageContext.pushScreen(() => const HelpScreen());
    case DrawerItemsEnum.registerShop:
      homepageContext.pushScreen(() => const ShopAuthScreen());
    case DrawerItemsEnum.signIn:
      homepageContext.pushScreen(() => const CustomerLogin());

    case DrawerItemsEnum.addresses:
      // A sheet, not a screen: the same surface checkout uses, opened in the
      // mode that manages the set rather than picking from it.
      AddressPickerSheet.show(
        homepageContext,
        mode: AddressSheetMode.manage,
      );
  }
}
