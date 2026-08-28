import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// A custom animated bottom navigation bar that replaces CurvedNavigationBar.
///
/// Features:
/// - Smooth icon + label animations
/// - Active indicator pill
/// - No external package dependency
class NearzyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NearzyNavItem> items;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;

  const NearzyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.card;
    final active = activeColor ?? AppColors.primary;
    final inactive = inactiveColor ?? AppColors.textTertiary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == currentIndex;
              final item = items[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: _NavItemWidget(
                    item: item,
                    isSelected: isSelected,
                    activeColor: active,
                    inactiveColor: inactive,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final NearzyNavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppSpacing.durationNormal,
      curve: AppSpacing.curveDefault,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active indicator pill
          AnimatedContainer(
            duration: AppSpacing.durationNormal,
            curve: AppSpacing.curveDefault,
            height: 3,
            width: isSelected ? 20 : 0,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
          ),
          // Icon with animated color
          AnimatedSwitcher(
            duration: AppSpacing.durationFast,
            child: Icon(
              isSelected ? item.selectedIcon : item.unselectedIcon,
              key: ValueKey('${item.label}_$isSelected'),
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 2),
          // Label
          AnimatedDefaultTextStyle(
            duration: AppSpacing.durationFast,
            style: AppTextStyles.navLabel.copyWith(
              color: isSelected ? activeColor : inactiveColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Badge
          if (item.badgeCount != null && item.badgeCount! > 0)
            Positioned(
              right: 0,
              top: 0,
              child: _Badge(count: item.badgeCount!),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppSpacing.durationNormal,
      curve: AppSpacing.curveSnap,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        child: Center(
          child: Text(
            count > 99 ? '99+' : count.toString(),
            style: AppTextStyles.badge.copyWith(fontSize: 9),
          ),
        ),
      ),
    );
  }
}

/// Data class for a navigation item.
class NearzyNavItem {
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final int? badgeCount;

  const NearzyNavItem({
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
    this.badgeCount,
  });
}
