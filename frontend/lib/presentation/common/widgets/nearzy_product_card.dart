import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../animations/pressable_scale.dart';
import 'nearzy_network_image.dart';

/// Product card used across the dashboard, explore and search grids.
///
/// The image dominates: a marketplace grid is browsed with the eyes, and text
/// that competes with the photo just slows that down.
class NearzyProductCard extends StatefulWidget {
  const NearzyProductCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.priceInPaise,
    this.discountedPriceInPaise,
    this.rating,
    this.shopName,
    this.categoryName,
    this.distanceLabel,
    this.isCompact = false,
    this.heroTag,
    this.isFavourite = false,
    this.onFavouriteToggle,
    this.onTap,
  });

  final String name;
  final String imageUrl;
  final int priceInPaise;
  final int? discountedPriceInPaise;
  final double? rating;
  final String? shopName;
  final String? categoryName;

  /// "1.2 km" — shown under the shop name when known.
  final String? distanceLabel;

  final bool isCompact;
  final String? heroTag;
  final bool isFavourite;
  final VoidCallback? onFavouriteToggle;
  final VoidCallback? onTap;

  @override
  State<NearzyProductCard> createState() => _NearzyProductCardState();
}

class _NearzyProductCardState extends State<NearzyProductCard> {
  /// Whole rupees with thousands separators — "₹12,749", not "₹12749.00".
  /// Paise never change a buying decision at grid density, and the extra
  /// glyphs are what push a discounted pair out of the card.
  static String _formatPrice(int paise) {
    final rupees = (paise / 100).round();
    final digits = rupees.abs().toString();

    // Indian grouping: last three digits, then pairs (12,34,567).
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      final needsComma =
          fromEnd > 3 ? (fromEnd - 3).isOdd : false;
      if (needsComma && fromEnd > 1) buffer.write(',');
    }
    return '₹${rupees < 0 ? '-' : ''}$buffer';
  }

  int? get _discountPercent {
    final discounted = widget.discountedPriceInPaise;
    if (discounted == null ||
        discounted >= widget.priceInPaise ||
        widget.priceInPaise <= 0) {
      return null;
    }
    return (((widget.priceInPaise - discounted) / widget.priceInPaise) * 100)
        .round();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isCompact ? _buildCompact(context) : _buildGrid(context);
  }

  // ── Grid layout ─────────────────────────────────────────────────────

  Widget _buildGrid(BuildContext context) {
    final discount = _discountPercent;

    return PressableScale(
      onTap: widget.onTap,
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
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.paperDim,
                    child: _image(),
                  ),
                  if (discount != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _DiscountBadge(percent: discount),
                    ),
                  if (widget.onFavouriteToggle != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: FavouriteButton(
                        isFavourite: widget.isFavourite,
                        onToggle: widget.onFavouriteToggle!,
                      ),
                    ),
                  if (widget.rating != null && widget.rating! > 0)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: _RatingPill(rating: widget.rating!),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flexible, not a bare Text: at large text scales a
                    // two-line title would otherwise overrun the rows below
                    // instead of shortening itself.
                    Flexible(
                      child: Text(
                        widget.name,
                        style: AppTextStyles.labelMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.shopName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined,
                              size: 11, color: AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              widget.distanceLabel == null
                                  ? widget.shopName!
                                  : '${widget.shopName!} · ${widget.distanceLabel}',
                              style: AppTextStyles.micro,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    _priceRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact list layout ─────────────────────────────────────────────

  Widget _buildCompact(BuildContext context) {
    return PressableScale(
      onTap: widget.onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppSpacing.shadowSubtle,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusMd,
              child: SizedBox(width: 72, height: 72, child: _image()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.name,
                    style: AppTextStyles.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.shopName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.shopName!,
                      style: AppTextStyles.micro,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  _priceRow(),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  // ── Pieces ──────────────────────────────────────────────────────────

  Widget _image() {
    final image = NearzyNetworkImage(
      url: widget.imageUrl,
      fit: BoxFit.cover,
      fallbackIcon: Icons.shopping_bag_outlined,
      semanticLabel: widget.name,
    );
    return widget.heroTag == null
        ? image
        : Hero(tag: widget.heroTag!, child: image);
  }

  Widget _priceRow() {
    final discounted = widget.discountedPriceInPaise;
    final hasDiscount = _discountPercent != null;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _formatPrice(hasDiscount ? discounted! : widget.priceInPaise),
            style: AppTextStyles.priceSmall,
            maxLines: 1,
          ),
          if (hasDiscount) ...[
            const SizedBox(width: 6),
            Text(
              _formatPrice(widget.priceInPaise),
              style: AppTextStyles.priceStrikethrough,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}

/// Heart toggle with a pop on activation.
class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    super.key,
    required this.isFavourite,
    required this.onToggle,
    this.size = 34,
  });

  final bool isFavourite;
  final VoidCallback onToggle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isFavourite ? 'Remove from saved' : 'Save for later',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onToggle();
        },
        behavior: HitTestBehavior.opaque,
        // The visible circle is small; this keeps the tap target at 44px.
        child: Padding(
          padding: EdgeInsets.all((44 - size) / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: AppSpacing.shadowSubtle,
            ),
            child: AnimatedSwitcher(
              duration: Motion.duration(context, Motion.quick),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Motion.spring),
                child: child,
              ),
              child: Icon(
                isFavourite ? Icons.favorite_rounded : Icons.favorite_border,
                key: ValueKey(isFavourite),
                size: size * 0.5,
                color: isFavourite ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        '$percent% off',
        style: AppTextStyles.badge.copyWith(color: AppColors.lime),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.94),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.badge.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
