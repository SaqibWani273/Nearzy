import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/bottom_navbar_items.dart';
import '../../../constants/drawer_data.dart';
import '../../../data/repositories/customer/customer_data_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/handle_drawer_item_tap.dart';
import '../../../services/session_manager.dart';
import '../animations/entrance.dart';
import '../animations/pressable_scale.dart';
import 'account_switcher_sheet.dart';
import 'nearzy_logo.dart';
import '../../features/customer/customer_home_page.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({
    super.key,
    required this.currentTab,
    required this.homePageContext,
  });

  /// Which bottom-nav tab is open, so the matching row reads as selected.
  /// This used to be a field on the shell that never changed, which left
  /// "Home" lit whatever was actually on screen.
  final int currentTab;

  final BuildContext homePageContext;

  /// The drawer row, if any, that stands for [currentTab].
  DrawerItemsEnum? get _selectedItem => switch (currentTab) {
        HomeTabScope.explore => DrawerItemsEnum.exploreShops,
        HomeTabScope.categories => DrawerItemsEnum.categories,
        HomeTabScope.home => DrawerItemsEnum.home,
        HomeTabScope.cart => DrawerItemsEnum.cart,
        HomeTabScope.profile => DrawerItemsEnum.profile,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CustomerDataRepository>();
    final customer = repository.customer;
    // Signed out, the account-only rows are left out rather than offered and
    // then failing — see `drawerItemsFor`.
    //
    // The role matters, not merely that some account is live: this shell also
    // renders when a session exists but its profile fetch failed, and the
    // orders and address endpoints would answer 401 for anyone else.
    final items = drawerItemsFor(
      signedIn: SessionManager.instance.active?.role == Roles.ROLE_CUSTOMER,
    );

    return Drawer(
      backgroundColor: AppColors.paper,
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          // Tapping it opens the account switcher. The drawer is reachable
          // from every customer screen, so this is the shortest path between
          // two accounts anywhere in the app.
          PressableScale(
            onTap: () {
              Navigator.pop(context);
              AccountSwitcherSheet.show(homePageContext);
            },
            scale: 0.99,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 28,
                24,
                28,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.inkGradient,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(AppSpacing.radiusXl),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NearzyLogo(size: 30, onInk: true),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer == null
                              ? 'Shops a few streets away'
                              : 'Hi, ${customer.user.username}',
                          style: AppTextStyles.heading3
                              .copyWith(color: AppColors.paper),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const _SwitchAffordance(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded,
                          size: 13, color: AppColors.lime),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          repository.currentSelectedLocation?.shortAddress ??
                              'Everywhere',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.sage),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Menu ────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _DrawerRow(
                  item: item,
                  selected: item.enumValue == _selectedItem,
                  onTap: () {
                    Navigator.pop(context);
                    handleDrawerItemTap(
                      enumValue: item.enumValue,
                      context: context,
                      homepageContext: homePageContext,
                    );
                  },
                ).animateEntrance(index: index, offset: 12);
              },
            ),
          ),

          const Divider(indent: 24, endIndent: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            child: Row(
              children: [
                Text('Nearzy', style: AppTextStyles.labelSmall),
                const SizedBox(width: 6),
                Text('v2.0 · Local first', style: AppTextStyles.micro),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MenuItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: PressableScale(
        onTap: onTap,
        scale: 0.97,
        child: AnimatedContainer(
          duration: Motion.duration(context, Motion.quick),
          curve: Motion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusFull,
          ),
          child: Row(
            children: [
              Icon(
                selected ? item.selectedIcon : item.unSelectedIcon,
                size: 20,
                color: selected ? AppColors.lime : AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: selected ? AppColors.paper : AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.lime),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge on the drawer header. Counts the other accounts held on this device,
/// so a second identity is visible rather than hidden behind a tap.
class _SwitchAffordance extends StatelessWidget {
  const _SwitchAffordance();

  @override
  Widget build(BuildContext context) {
    final others = SessionManager.instance.otherAccounts.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inkSoft,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.lime),
          const SizedBox(width: 4),
          Text(
            others == 0 ? 'Accounts' : '$others more',
            style: AppTextStyles.micro.copyWith(color: AppColors.lime),
          ),
        ],
      ),
    );
  }
}
