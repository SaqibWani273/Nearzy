import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final IconData selectedIcon;
  final IconData unSelectedIcon;
  final DrawerItemsEnum enumValue;

  const MenuItem({
    required this.title,
    required this.selectedIcon,
    required this.unSelectedIcon,
    required this.enumValue,
  });
}

/// Everything the drawer can offer, in the order it reads best.
///
/// Two rules, both of which the previous list broke:
///
///   * **A row's label is where it goes.** "Your Orders" opened the profile
///     tab; "Shop" opened the Explore tab. Both are handled in
///     [handleDrawerItemTap], and both now land where the words say.
///   * **A row only appears if it works right now.** Orders, addresses and
///     the profile all need a session — signed out they were dead ends, so
///     [drawerItemsFor] leaves them out and offers "Sign in" instead.
const List<MenuItem> _allMenuItems = [
  MenuItem(
    title: 'Home',
    selectedIcon: Icons.home,
    unSelectedIcon: Icons.home_outlined,
    enumValue: DrawerItemsEnum.home,
  ),
  MenuItem(
    title: 'Explore shops',
    selectedIcon: Icons.explore_rounded,
    unSelectedIcon: Icons.explore_outlined,
    enumValue: DrawerItemsEnum.exploreShops,
  ),
  MenuItem(
    title: 'Categories',
    selectedIcon: Icons.grid_view_rounded,
    unSelectedIcon: Icons.grid_view_outlined,
    enumValue: DrawerItemsEnum.categories,
  ),
  MenuItem(
    title: 'Special offers',
    selectedIcon: Icons.card_giftcard_rounded,
    unSelectedIcon: Icons.card_giftcard_outlined,
    enumValue: DrawerItemsEnum.specialOffers,
  ),
  MenuItem(
    title: 'Saved items',
    selectedIcon: Icons.favorite,
    unSelectedIcon: Icons.favorite_border_outlined,
    enumValue: DrawerItemsEnum.savedItems,
  ),
  MenuItem(
    title: 'Cart',
    selectedIcon: Icons.shopping_bag_rounded,
    unSelectedIcon: Icons.shopping_bag_outlined,
    enumValue: DrawerItemsEnum.cart,
  ),
  MenuItem(
    title: 'Your orders',
    selectedIcon: Icons.receipt_long_rounded,
    unSelectedIcon: Icons.receipt_long_outlined,
    enumValue: DrawerItemsEnum.yourOrders,
  ),
  MenuItem(
    title: 'Delivery addresses',
    selectedIcon: Icons.location_on_rounded,
    unSelectedIcon: Icons.location_on_outlined,
    enumValue: DrawerItemsEnum.addresses,
  ),
  MenuItem(
    title: 'Profile',
    selectedIcon: Icons.account_circle_rounded,
    unSelectedIcon: Icons.account_circle_outlined,
    enumValue: DrawerItemsEnum.profile,
  ),
  MenuItem(
    title: 'Sign in',
    selectedIcon: Icons.login_rounded,
    unSelectedIcon: Icons.login_rounded,
    enumValue: DrawerItemsEnum.signIn,
  ),
  MenuItem(
    title: 'Sell on Nearzy',
    selectedIcon: Icons.storefront_rounded,
    unSelectedIcon: Icons.storefront_outlined,
    enumValue: DrawerItemsEnum.registerShop,
  ),
  MenuItem(
    title: 'Help & support',
    selectedIcon: Icons.help_outline_rounded,
    unSelectedIcon: Icons.help_outline_outlined,
    enumValue: DrawerItemsEnum.helpAndSupport,
  ),
];

/// The rows that are actually usable for the current session.
///
/// [signedIn] false hides the three account-only destinations — the orders
/// list and the address book both call authenticated endpoints and would have
/// come back empty-handed — and surfaces a sign-in row in their place.
List<MenuItem> drawerItemsFor({required bool signedIn}) {
  const accountOnly = {
    DrawerItemsEnum.yourOrders,
    DrawerItemsEnum.addresses,
    DrawerItemsEnum.profile,
  };

  return _allMenuItems.where((item) {
    if (item.enumValue == DrawerItemsEnum.signIn) return !signedIn;
    if (accountOnly.contains(item.enumValue)) return signedIn;
    return true;
  }).toList();
}

enum DrawerItemsEnum {
  home,
  exploreShops,
  categories,
  specialOffers,
  savedItems,
  cart,
  yourOrders,
  addresses,
  profile,
  signIn,
  registerShop,
  helpAndSupport,
}
