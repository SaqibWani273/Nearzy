import 'package:flutter/material.dart';

import '../../../../../data/models/shop_verification.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/widgets/nearzy_network_image.dart';

/// One application, as a reviewable card.
///
/// The two identity documents sit side by side because that is the comparison
/// the reviewer is actually making — does the name on the PAN card match the
/// ID? Stacking them vertically would put a scroll between the two halves of
/// a single judgement.
class VerificationCard extends StatelessWidget {
  const VerificationCard({
    super.key,
    required this.verification,
    this.onOpenDocument,
  });

  final ShopVerification verification;
  final void Function(VerificationDocument)? onOpenDocument;

  @override
  Widget build(BuildContext context) {
    final shop = verification.shop;
    final docs = verification.documents;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppSpacing.shadowSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verification.shopName, style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  verification.ownerName,
                  style: AppTextStyles.bodySmall,
                ),
                if (shop?.locationInfo.shortAddress.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          shop!.locationInfo.shortAddress,
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: docs.isEmpty
                  ? const _NoDocuments()
                  : Row(
                      children: [
                        for (var i = 0; i < docs.length && i < 2; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _DocumentPane(
                              document: docs[i],
                              onTap: onOpenDocument == null
                                  ? null
                                  : () => onOpenDocument!(docs[i]),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  docs.isEmpty
                      ? 'No documents supplied'
                      : '${docs.length} ${docs.length == 1 ? 'document' : 'documents'}',
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                if (verification.submittedAt != null)
                  Text(
                    _age(verification.submittedAt!),
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// How long this applicant has been waiting — the reviewer's own backlog,
  /// which the oldest-first queue makes meaningful.
  static String _age(DateTime submitted) {
    final days = DateTime.now().difference(submitted).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 30) return '$days days ago';
    final months = (days / 30).floor();
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  }
}

class _DocumentPane extends StatelessWidget {
  const _DocumentPane({required this.document, this.onTap});

  final VerificationDocument document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(document.label, style: AppTextStyles.overline),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusMd,
              child: NearzyNetworkImage(
                url: document.url,
                width: double.infinity,
                height: double.infinity,
                fallbackIcon: Icons.broken_image_outlined,
                semanticLabel: '${document.label} submitted for verification',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An application with no paperwork is a decision in itself — the reviewer
/// should see the absence stated, not an empty gap they might read as a
/// loading failure.
class _NoDocuments extends StatelessWidget {
  const _NoDocuments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paperDim,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_off_outlined,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No documents submitted',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
