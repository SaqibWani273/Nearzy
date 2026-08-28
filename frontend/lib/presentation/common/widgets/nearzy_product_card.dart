import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Reusable product card used across the app (dashboard, explore, search).
///
/// Supports both grid and list layouts via [isCompact].
class NearzyProductCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final int priceInPaise;
  final int? discountedPriceInPaise;
  final double? rating;
  final String? shopName;
  final String? categoryName;
  final bool isCompact;
  final VoidCallback? onTap;

  const NearzyProductCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.priceInPaise,
    this.discountedPriceInPaise,
    this.rating,
    this.shopName,
    this.categoryName,
    this.isCompact = false,
    this.onTap,
  });

  @override
  State<NearzyProductCard> createState() => _NearzyProductCardState();
}

class _NearzyProductCardState extends State<NearzyProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String _formatPrice(int paise) {
    final rupees = paise ~/ 100;
    return '₹$rupees';
  }

  int? get _discountPercent {
    if (widget.discountedPriceInPaise != null &&
        widget.discountedPriceInPaise! < widget.priceInPaise) {
      return (((widget.priceInPaise - widget.discountedPriceInPaise!) /
                  widget.priceInPaise) *
              100)
          .round();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = _discountPercent != null && _discountPercent! > 0;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppSpacing.borderRadiusMd,
            boxShadow: AppSpacing.shadowCard,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product_${widget.name}_${widget.imageUrl}',
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.inputFill,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.textTertiary,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // Discount badge
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Text(
                            '${_discountPercent}% OFF',
                            style: AppTextStyles.badge,
                          ),
                        ),
                      ),
                    // Rating
                    if (widget.rating != null && widget.rating! > 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.card.withValues(alpha: 0.95),
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.warning),
                              const SizedBox(width: 2),
                              Text(
                                widget.rating!.toStringAsFixed(1),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // ── Details ────────────────────────────────────────────
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name
                      Text(
                        widget.name,
                        style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.shopName != null && !widget.isCompact)
                        Text(
                          widget.shopName!,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      // Price
                      Row(
                        children: [
                          Text(
                            hasDiscount
                                ? _formatPrice(widget.discountedPriceInPaise!)
                                : _formatPrice(widget.priceInPaise),
                            style: AppTextStyles.priceSmall,
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 6),
                            Text(
                              _formatPrice(widget.priceInPaise),
                              style: AppTextStyles.priceStrikethrough,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
