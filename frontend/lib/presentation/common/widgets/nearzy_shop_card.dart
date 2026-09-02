import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../animations/pressable_scale.dart';
import 'nearzy_network_image.dart';

/// Shop card for the Explore grid.
///
/// Cover image on top, details below, with the distance badge floating over
/// the image — that badge is the single most useful fact on a hyperlocal
/// marketplace, so it gets the most prominent position.
class NearzyShopCard extends StatelessWidget {
  const NearzyShopCard({
    super.key,
    required this.name,
    required this.imageUrl,
    this.address,
    this.categories = const [],
    this.isVerified = false,
    this.distanceLabel,
    this.heroTag,
    this.onTap,
  });

  final String name;
  final String imageUrl;
  final String? address;
  final List<String> categories;
  final bool isVerified;

  /// "1.2 km" — omitted when the shop's distance is unknown.
  final String? distanceLabel;

  /// Shared with the detail screen's header so the cover image flies between
  /// them instead of cutting.
  final String? heroTag;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppSpacing.shadowSoft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _cover(),
                  // Scrim so the badges stay readable over a light photo.
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.imageScrim),
                  ),
                  if (distanceLabel != null)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: _Pill(
                        icon: Icons.near_me_rounded,
                        label: distanceLabel!,
                      ),
                    ),
                  if (isVerified)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: _VerifiedDot(),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.heading4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (address != null && address!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        address!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    if (categories.isNotEmpty)
                      // A single row that clips, rather than a Wrap that can
                      // overflow the card when a category name is long.
                      SizedBox(
                        height: 22,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categories.length.clamp(0, 3),
                          separatorBuilder: (_, _) => const SizedBox(width: 5),
                          itemBuilder: (context, i) => _CategoryChip(
                            label: categories[i],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover() {
    final image = NearzyNetworkImage(
      url: imageUrl,
      fit: BoxFit.cover,
      fallbackIcon: Icons.storefront_rounded,
      semanticLabel: name,
    );
    return heroTag == null ? image : Hero(tag: heroTag!, child: image);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.ink),
          const SizedBox(width: 3),
          Text(label,
              style: AppTextStyles.badge.copyWith(color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _VerifiedDot extends StatelessWidget {
  const _VerifiedDot();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verified shop',
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          boxShadow: AppSpacing.shadowSubtle,
        ),
        child: const Icon(Icons.verified_rounded,
            size: 15, color: AppColors.info),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.sageSurface,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        label,
        style: AppTextStyles.micro.copyWith(
          color: AppColors.sageDeep,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
