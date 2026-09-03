import 'package:flutter/material.dart';

import '../../../../../../data/models/category/product_category/product_category.dart';
import '../../../../../../theme/app_colors.dart';
import '../../../../../../theme/app_motion.dart';
import '../../../../../../theme/app_spacing.dart';
import '../../../../../../theme/app_text_styles.dart';
import '../../../../../common/animations/entrance.dart';
import '../../../../../common/animations/pressable_scale.dart';
import '../../../../../common/widgets/nearzy_network_image.dart';

/// The feed's category filter.
///
/// Selection changes the grid underneath rather than pushing a new screen:
/// on a hyperlocal feed "show me only bakeries" is a lens on what's already
/// here, not a different destination.
class CategoryRail extends StatelessWidget {
  const CategoryRail({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<ProductCategory> categories;

  /// The active filter, or null for the unfiltered feed.
  final ProductCategory? selected;

  /// Called with null to clear the filter.
  final ValueChanged<ProductCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        // One leading "All" chip, then the categories.
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryChip(
              label: 'All',
              icon: Icons.auto_awesome_mosaic_rounded,
              isSelected: selected == null,
              onTap: () => onSelect(null),
            ).animateEntrance(horizontal: true, offset: 20);
          }

          final category = categories[index - 1];
          final isSelected = selected?.id == category.id;
          return _CategoryChip(
            label: category.name,
            imageUrl: category.image,
            isSelected: isSelected,
            // Tapping the active chip clears it — the same gesture in and
            // back out, so the filter never becomes a trap.
            onTap: () => onSelect(isSelected ? null : category),
          ).animateEntrance(index: index, horizontal: true, offset: 20);
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.imageUrl,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? imageUrl;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? AppColors.paper : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label category filter',
      child: PressableScale(
        onTap: onTap,
        scale: 0.94,
        child: AnimatedContainer(
          duration: Motion.duration(context, Motion.quick),
          curve: Motion.easeOut,
          padding: EdgeInsets.only(
            left: imageUrl != null ? 6 : 14,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ink : AppColors.card,
            borderRadius: AppSpacing.borderRadiusFull,
            border: Border.all(
              color: isSelected ? AppColors.ink : AppColors.line,
            ),
            boxShadow: isSelected ? AppSpacing.shadowSoft : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null)
                ClipOval(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: NearzyNetworkImage(
                      url: imageUrl,
                      fallbackIcon: Icons.category_outlined,
                      semanticLabel: label,
                    ),
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(color: foreground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
