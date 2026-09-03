import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/animations/pressable_scale.dart';

/// One thing the owner should deal with.
///
/// Deliberately not a statistic tile: every card names an action and resolves
/// in one tap. A number the owner cannot act on belongs in the quieter
/// inventory strip, not here.
class TriageCard extends StatelessWidget {
  const TriageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.surface,
    required this.actionLabel,
    this.onTap,
    this.onDismiss,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color surface;
  final String actionLabel;
  final VoidCallback? onTap;

  /// Shown as a quiet secondary control. Absent for cards that describe a
  /// state rather than a notification — you cannot dismiss "3 orders pending",
  /// you can only go and pack them.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppSpacing.shadowSubtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall,
                        // Never clipped to a fixed height — the copy carries
                        // real numbers and must survive 1.3x text scale.
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (onDismiss != null) ...[
                  _QuietAction(
                    label: 'Dismiss',
                    onTap: onDismiss!,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.lime),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.lime,
                      ),
                    ],
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

class _QuietAction extends StatelessWidget {
  const _QuietAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        foregroundColor: AppColors.textSecondary,
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }
}
