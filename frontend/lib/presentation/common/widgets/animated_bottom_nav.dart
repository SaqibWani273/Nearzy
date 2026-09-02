import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Floating ink navigation bar.
///
/// A single lime pill slides between destinations rather than each item
/// animating on its own — one moving object reads as a control, five reads as
/// noise. The pill is driven by a `TweenAnimationBuilder` on the index, so it
/// interpolates smoothly even when the index jumps by more than one.
class NearzyBottomNav extends StatelessWidget {
  const NearzyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NearzyNavItem> items;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final background = backgroundColor ?? AppColors.ink;
    final active = activeColor ?? AppColors.ink;
    final inactive = inactiveColor ?? AppColors.sage;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        MediaQuery.of(context).padding.bottom > 0 ? 8 : 16,
      ),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppSpacing.borderRadiusFull,
          boxShadow: AppSpacing.shadowFloating,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slot = constraints.maxWidth / items.length;
            return Stack(
              children: [
                // The travelling pill.
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: currentIndex.toDouble(),
                    end: currentIndex.toDouble(),
                  ),
                  duration: Motion.duration(context, Motion.base),
                  curve: Motion.spring,
                  builder: (context, value, child) => Positioned(
                    left: slot * value + 4,
                    top: 8,
                    width: slot - 8,
                    height: 52,
                    child: child!,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavItemWidget(
                          item: items[i],
                          isSelected: i == currentIndex,
                          activeColor: active,
                          inactiveColor: inactive,
                          onTap: () {
                            if (i == currentIndex) return;
                            HapticFeedback.selectionClick();
                            onTap(i);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final NearzyNavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // A tiny scale bump on selection gives the tap a physical
                  // response the sliding pill alone doesn't provide.
                  AnimatedScale(
                    scale: isSelected ? 1.0 : 0.92,
                    duration: Motion.duration(context, Motion.base),
                    curve: Motion.spring,
                    child: Icon(
                      isSelected ? item.selectedIcon : item.unselectedIcon,
                      size: 22,
                      color: color,
                    ),
                  ),
                  if (item.badgeCount != null && item.badgeCount! > 0)
                    Positioned(
                      right: -8,
                      top: -5,
                      child: _Badge(
                        count: item.badgeCount!,
                        onLime: isSelected,
                      ),
                    ),
                ],
              ),
              // The label only shows on the selected item — five labels under
              // five icons is what makes stock nav bars look cramped.
              AnimatedSize(
                duration: Motion.duration(context, Motion.base),
                curve: Motion.easeOut,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          item.label,
                          style: AppTextStyles.navLabel.copyWith(color: color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : const SizedBox(width: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.onLime});

  final int count;

  /// Badge sits on the lime pill when its item is selected, so it has to
  /// flip to ink to stay visible.
  final bool onLime;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Motion.duration(context, Motion.base),
      curve: Motion.spring,
      builder: (context, value, child) =>
          Transform.scale(scale: value.clamp(0.0, 1.4), child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: onLime ? AppColors.ink : AppColors.lime,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        child: Center(
          child: Text(
            count > 9 ? '9+' : '$count',
            style: AppTextStyles.badge.copyWith(
              color: onLime ? AppColors.lime : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for a navigation item.
class NearzyNavItem {
  const NearzyNavItem({
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
    this.badgeCount,
  });

  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final int? badgeCount;

  NearzyNavItem copyWith({int? badgeCount}) => NearzyNavItem(
        label: label,
        selectedIcon: selectedIcon,
        unselectedIcon: unselectedIcon,
        badgeCount: badgeCount ?? this.badgeCount,
      );
}
