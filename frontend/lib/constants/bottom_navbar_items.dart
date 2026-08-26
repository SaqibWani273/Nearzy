import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mca_project/presentation/features/shop/orders/orders_screen.dart';
import '../presentation/features/customer/shops/shops_screen.dart';
import '../presentation/features/shop/inventory/shop_inventory_screen.dart';
import '../presentation/features/shop/shop_profile/shop_profile_screen.dart';
import '/presentation/features/customer/cart/cart_screen.dart';
import '/presentation/features/customer/profile/customer_profile.dart';
import '../presentation/features/customer/categories/view/categories_screen.dart';
import '../presentation/features/customer/dashboard/view/dashoard.dart';

class BottomNavbarItem {
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;

  BottomNavbarItem({
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
  });
}

BottomNavbarItem profileNavbarItem = BottomNavbarItem(
  label: 'Profile',
  selectedIcon: Icons.person_rounded,
  unselectedIcon: Icons.person_outlined,
);
List<BottomNavbarItem> customerBottomNavbarItems = [
  BottomNavbarItem(
    label: 'Categories',
    selectedIcon: Icons.category_rounded,
    unselectedIcon: Icons.category_outlined,
  ),
  BottomNavbarItem(
    label: 'Shop',
    selectedIcon: Icons.shop_sharp,
    unselectedIcon: Icons.shop_2_outlined,
  ),
  BottomNavbarItem(
    label: 'Home',
    selectedIcon: CupertinoIcons.home,
    unselectedIcon: Icons.home_outlined,
  ),
  BottomNavbarItem(
    label: 'Cart',
    selectedIcon: Icons.shopping_cart_rounded,
    unselectedIcon: Icons.shopping_cart_outlined,
  ),
  profileNavbarItem,
];

List<Widget> customerMainScreens = [
  const CategoriesScreen(),
  ShopsScreen(),
  const Dashboard(),
  CartScreen(),
  CustomerProfile(),
];

List<BottomNavbarItem> shopBottomNavbarItems = [
  BottomNavbarItem(
    label: 'Orders',
    selectedIcon: Icons.card_giftcard_sharp,
    unselectedIcon: Icons.card_giftcard_outlined,
  ),
  BottomNavbarItem(
    label: 'Inventory',
    selectedIcon: Icons.inventory_2_rounded,
    unselectedIcon: Icons.inventory_2_outlined,
  ),
  profileNavbarItem,
];
List<Widget> shopMainScreens = [
  OrdersScreen(
    role: Roles.ROLE_SHOP,
  ),
  ShopInventoryScreen(),
  ShopProfileScreen(),
];
