import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/drawer_data.dart';
import '../../../data/repositories/customer/customer_data_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/handle_drawer_item_tap.dart';
import '../animations/entrance.dart';
import '../animations/pressable_scale.dart';
import 'nearzy_logo.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({
    super.key,
    required this.currentIndex,
    required this.homePageContext,
  });

  final int currentIndex;
  final BuildContext homePageContext;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CustomerDataRepository>();
    final customer = repository.customer;

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
          Container(
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
                Text(
                  customer == null
                      ? 'Shops a few streets away'
                      : 'Hi, ${customer.user.username}',
                  style:
                      AppTextStyles.heading3.copyWith(color: AppColors.paper),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

          // ── Menu ────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _DrawerRow(
                  item: item,
                  selected: currentIndex == index,
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
