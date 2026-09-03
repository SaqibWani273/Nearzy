import 'package:flutter/material.dart';

import '../../../../../../data/models/shop_model/shop_model1.dart';
import '../../../../../../theme/app_colors.dart';
import '../../../../../../theme/app_motion.dart';
import '../../../../../../theme/app_spacing.dart';
import '../../../../../../theme/app_text_styles.dart';
import '../../../../../common/animations/cross_fade.dart';
import '../../../../../common/animations/pressable_scale.dart';

/// The feed's opening block: who's shopping, where, and what's live around
/// them right now.
///
/// The three counters are the point. A hyperlocal marketplace has to answer
/// "is there anything here for me?" before it asks anyone to scroll, and a
/// number that counts itself up on arrival answers that faster than a
/// paragraph would. Each one is also a shortcut to the screen it describes.
class DashboardHero extends StatelessWidget {
  const DashboardHero({
    super.key,
    required this.customerName,
    required this.location,
    required this.radiusKm,
    required this.busy,
    required this.onChangeLocation,
    required this.shopCount,
    required this.dealCount,
    required this.savedCount,
    required this.onShops,
    required this.onDeals,
    required this.onSaved,
  });

  /// Null when signed out — the greeting stays warm without a name.
  final String? customerName;

  final LocationInfo? location;
  final double radiusKm;

  /// True while a location change is resolving.
  final bool busy;

  final VoidCallback onChangeLocation;

  /// Null until the matching rail resolves; renders as a placeholder dash
  /// rather than a premature zero, which would read as "nothing here".
  final int? shopCount;
  final int? dealCount;
  final int? savedCount;

  final VoidCallback onShops;
  final VoidCallback onDeals;
  final VoidCallback onSaved;

  static String _greeting(int hour) {
    if (hour < 5) return 'UP LATE';
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    if (hour < 21) return 'GOOD EVENING';
    return 'GOOD NIGHT';
  }

  String get _name {
    final raw = customerName?.trim();
    if (raw == null || raw.isEmpty) return 'Hey there';
    // Usernames arrive lower-cased from the backend; a greeting reads as a
    // greeting only when the name is capitalised.
    return 'Hey, ${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final area = location?.shortAddress ?? 'Everywhere';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        4,
        AppSpacing.gutter,
        4,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        decoration: BoxDecoration(
          gradient: AppColors.inkGradient,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppSpacing.shadowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(DateTime.now().hour),
              style: AppTextStyles.overline.copyWith(color: AppColors.sage),
            ),
            const SizedBox(height: 4),
            Text(
              _name,
              style: AppTextStyles.heading2.copyWith(color: AppColors.paper),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            _LocationRow(
              area: area,
              radiusKm: radiusKm,
              busy: busy,
              onTap: onChangeLocation,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: AppColors.inkMuted),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: shopCount,
                    label: 'SHOPS',
                    semanticNoun: 'shops nearby',
                    onTap: onShops,
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _Stat(
                    value: dealCount,
                    label: 'DEALS',
                    semanticNoun: 'deals nearby',
                    onTap: onDeals,
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _Stat(
                    value: savedCount,
                    label: 'SAVED',
                    semanticNoun: 'saved items',
                    onTap: onSaved,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the feed is scoped to, and the way out of it.
class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.area,
    required this.radiusKm,
    required this.busy,
    required this.onTap,
  });

  final String area;
  final double radiusKm;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.985,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place_rounded,
                size: 17, color: AppColors.ink),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHOPPING IN',
                  style: AppTextStyles.micro.copyWith(color: AppColors.sage),
                ),
                const SizedBox(height: 1),
                CrossFade(
                  state: busy ? 'busy' : area,
                  child: Text(
                    busy ? 'Updating…' : '$area · ${radiusKm.round()} km',
                    style: AppTextStyles.heading4
                        .copyWith(color: AppColors.paper),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.inkMuted,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Text(
              'Change',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.paper),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 26,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.inkMuted,
        ),
      );
}

/// One counter. Counts up from zero on arrival and re-counts when the number
/// changes, so a refresh that finds two more shops is visible rather than a
/// silent swap.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.semanticNoun,
    required this.onTap,
  });

  final int? value;
  final String label;
  final String semanticNoun;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final known = value;

    return Semantics(
      button: true,
      label:
          known == null ? 'Loading $semanticNoun' : '$known $semanticNoun',
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        scale: 0.93,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              if (known == null)
                Text(
                  '—',
                  style: AppTextStyles.heading3
                      .copyWith(color: AppColors.inkMuted),
                )
              else
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: known.toDouble()),
                  duration: Motion.duration(context, Motion.slow),
                  curve: Motion.easeOut,
                  builder: (context, animated, _) => Text(
                    '${animated.round()}',
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.paper),
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.micro.copyWith(color: AppColors.sage),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
