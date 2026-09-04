import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// A failed sign-in, stated where the person is already looking.
///
/// The three login screens each used to report a failure differently — a
/// snackbar that vanished before it could be read, a full-screen error page
/// that threw the typed-in form away, and nothing at all. This is the one
/// answer: the form stays exactly as it was and gains a line above the fields
/// saying what to fix.
///
/// Renders nothing at all when [message] is null, so a screen can pass its
/// error state straight through without branching.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, this.onDismiss});

  final String? message;

  /// Optional close affordance. Worth wiring where the banner sits above a
  /// long form, so it can be cleared without another failed attempt.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = message;

    // Height animates from zero so the banner pushes the form down rather
    // than appearing over it — a jump would hide the field being corrected.
    return AnimatedSize(
      duration: Motion.duration(context, Motion.base),
      curve: Motion.emphasis,
      alignment: Alignment.topCenter,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : _Body(message: text, onDismiss: onDismiss),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.error_outline_rounded,
                size: 19,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  height: 1.45,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: AppColors.error,
                ),
              )
            else
              const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
