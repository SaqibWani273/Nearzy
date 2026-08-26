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

List<MenuItem> menuItems = [
  const MenuItem(
    title: 'Home',
    selectedIcon: Icons.home,
    unSelectedIcon: Icons.home_outlined,
    enumValue: DrawerItemsEnum.home,
  ),
  const MenuItem(
    title: 'Favourites',
    selectedIcon: Icons.favorite,
    unSelectedIcon: Icons.favorite_border_outlined,
    enumValue: DrawerItemsEnum.favourites,
  ),
  const MenuItem(
    title: 'Special Offers',
    selectedIcon: Icons.card_giftcard_rounded,
    unSelectedIcon: Icons.card_giftcard_outlined,
    enumValue: DrawerItemsEnum.specialOffers,
  ),
  const MenuItem(
    title: 'Categories',
    selectedIcon: Icons.category_outlined,
    unSelectedIcon: Icons.category_outlined,
    enumValue: DrawerItemsEnum.categories,
  ),
  const MenuItem(
    title: 'Shop',
    selectedIcon: Icons.shop_2_outlined,
    unSelectedIcon: Icons.shop_2_outlined,
    enumValue: DrawerItemsEnum.shop,
  ),
  const MenuItem(
    title: 'Your Orders',
    selectedIcon: Icons.list,
    unSelectedIcon: Icons.list_alt_outlined,
    enumValue: DrawerItemsEnum.yourOrders,
  ),
  const MenuItem(
    title: 'Cart',
    selectedIcon: Icons.shopping_cart_outlined,
    unSelectedIcon: Icons.shopping_cart_outlined,
    enumValue: DrawerItemsEnum.cart,
  ),
  const MenuItem(
    title: 'Profile',
    selectedIcon: Icons.account_circle_rounded,
    unSelectedIcon: Icons.account_circle_outlined,
    enumValue: DrawerItemsEnum.profile,
  ),
  const MenuItem(
    title: 'Register Shop',
    selectedIcon: Icons.business_rounded,
    unSelectedIcon: Icons.business_outlined,
    enumValue: DrawerItemsEnum.registerShop,
  ),
  const MenuItem(
    title: 'Help & Support',
    selectedIcon: Icons.help_outline_rounded,
    unSelectedIcon: Icons.help_outline_outlined,
    enumValue: DrawerItemsEnum.helpAndSupport,
  ),
];
//enum for all the above drawer-items

enum DrawerItemsEnum {
  home,
  favourites,
  specialOffers,
  categories,
  shop,
  yourOrders,
  cart,
  profile,
  registerShop,
  helpAndSupport,
}
