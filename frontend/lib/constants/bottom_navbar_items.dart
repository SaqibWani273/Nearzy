import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../presentation/common/widgets/animated_bottom_nav.dart';
import '../presentation/features/customer/shops/shops_screen.dart';
import '../presentation/features/shop/inventory/shop_inventory_screen.dart';
import '../presentation/features/shop/orders/orders_screen.dart';
import '../presentation/features/shop/shop_profile/shop_profile_screen.dart';
import '/presentation/features/customer/cart/cart_screen.dart';
import '/presentation/features/customer/profile/customer_profile.dart';
import '../presentation/features/customer/categories/view/categories_screen.dart';
import '../presentation/features/customer/dashboard/view/dashoard.dart';

// ── Customer nav ──────────────────────────────────────────────────────

List<NearzyNavItem> customerNavItems = [
  const NearzyNavItem(
    label: 'Explore',
    selectedIcon: Icons.explore_rounded,
    unselectedIcon: Icons.explore_outlined,
  ),
  const NearzyNavItem(
    label: 'Categories',
    selectedIcon: Icons.grid_view_rounded,
    unselectedIcon: Icons.grid_view_outlined,
  ),
  const NearzyNavItem(
    label: 'Home',
    selectedIcon: CupertinoIcons.house_fill,
    unselectedIcon: CupertinoIcons.house,
  ),
  const NearzyNavItem(
    label: 'Cart',
    selectedIcon: Icons.shopping_bag_rounded,
    unselectedIcon: Icons.shopping_bag_outlined,
  ),
  const NearzyNavItem(
    label: 'Profile',
    selectedIcon: Icons.person_rounded,
    unselectedIcon: Icons.person_outline_rounded,
  ),
];

List<Widget> customerMainScreens = [
  ShopsScreen(), // Explore tab — showing nearby shops
  const CategoriesScreen(),
  const Dashboard(),
  CartScreen(),
  CustomerProfile(),
];

// ── Shop Owner nav ────────────────────────────────────────────────────

List<NearzyNavItem> shopNavItems = [
  const NearzyNavItem(
    label: 'Orders',
    selectedIcon: Icons.receipt_long_rounded,
    unselectedIcon: Icons.receipt_long_outlined,
  ),
  const NearzyNavItem(
    label: 'Inventory',
    selectedIcon: Icons.inventory_2_rounded,
    unselectedIcon: Icons.inventory_2_outlined,
  ),
  const NearzyNavItem(
    label: 'Profile',
    selectedIcon: Icons.storefront_rounded,
    unselectedIcon: Icons.storefront_outlined,
  ),
];

List<Widget> shopMainScreens = [
  OrdersScreen(role: Roles.ROLE_SHOP),
  ShopInventoryScreen(),
  ShopProfileScreen(),
];

// ── Admin nav ─────────────────────────────────────────────────────────

List<NearzyNavItem> adminNavItems = [
  const NearzyNavItem(
    label: 'Dashboard',
    selectedIcon: Icons.dashboard_rounded,
    unselectedIcon: Icons.dashboard_outlined,
  ),
  const NearzyNavItem(
    label: 'Categories',
    selectedIcon: Icons.category_rounded,
    unselectedIcon: Icons.category_outlined,
  ),
  const NearzyNavItem(
    label: 'Shops',
    selectedIcon: Icons.store_rounded,
    unselectedIcon: Icons.store_outlined,
  ),
];

/// Roles enum shared across the app.
enum Roles { ROLE_CUSTOMER, ROLE_SHOP, ROLE_ADMIN }

/// Legacy BottomNavbarItem for backwards compat during migration.
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
    label: 'Explore',
    selectedIcon: Icons.explore_rounded,
    unselectedIcon: Icons.explore_outlined,
  ),
  BottomNavbarItem(
    label: 'Categories',
    selectedIcon: Icons.grid_view_rounded,
    unselectedIcon: Icons.grid_view_outlined,
  ),
  BottomNavbarItem(
    label: 'Home',
    selectedIcon: CupertinoIcons.house_fill,
    unselectedIcon: CupertinoIcons.house,
  ),
  BottomNavbarItem(
    label: 'Cart',
    selectedIcon: Icons.shopping_bag_rounded,
    unselectedIcon: Icons.shopping_bag_outlined,
  ),
  profileNavbarItem,
];

List<BottomNavbarItem> shopBottomNavbarItems = [
  BottomNavbarItem(
    label: 'Orders',
    selectedIcon: Icons.receipt_long_rounded,
    unselectedIcon: Icons.receipt_long_outlined,
  ),
  BottomNavbarItem(
    label: 'Inventory',
    selectedIcon: Icons.inventory_2_rounded,
    unselectedIcon: Icons.inventory_2_outlined,
  ),
  profileNavbarItem,
];
