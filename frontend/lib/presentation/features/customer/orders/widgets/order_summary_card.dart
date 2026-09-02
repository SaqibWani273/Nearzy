import 'package:flutter/material.dart';

import '../../../../../data/models/order.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../utils/money.dart';
import '../../../../common/animations/pressable_scale.dart';
import '../../../../common/widgets/nearzy_network_image.dart';
import 'order_status_chip.dart';

/// One order in a list: a stack of item thumbnails, the shop it came from,
/// the total, and where it has got to.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.order,
    this.onTap,
  });

  final Order order;
  final VoidCallback? onTap;

  /// "2 items from Kashmir Shawl House"
  String get _subtitle {
    final count = order.itemCount;
    final unit = count == 1 ? 'item' : 'items';
    final shops = order.shopNames;
    if (shops.isEmpty) return '$count $unit';
    if (shops.length == 1) return '$count $unit from ${shops.first}';
    return '$count $unit from ${shops.length} shops';
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppSpacing.shadowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Thumbnails(items: order.items),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _subtitle,
                        style: AppTextStyles.labelLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order.placedAt == null
                            ? order.orderNumber
                            : _relativeDate(order.placedAt!),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(Money.exact(order.totalAmountPaise),
                    style: AppTextStyles.priceSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: AppColors.line),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                OrderStatusChip(status: order.status),
                const SizedBox(width: AppSpacing.sm),
                PaymentStatusChip(status: order.paymentStatus),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Up to three overlapping item thumbnails, with a "+N" tile when there are
/// more. Cheaper to scan than a list of names at list density.
class _Thumbnails extends StatelessWidget {
  const _Thumbnails({required this.items});

  final List<OrderLine> items;

  static const double _size = 46;
  static const double _step = 30;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(3).toList();
    final extra = items.length - visible.length;
    final width = visible.isEmpty
        ? _size
        : _size + _step * (visible.length - 1) + (extra > 0 ? _step : 0);

    return SizedBox(
      width: width,
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * _step,
              child: _Tile(url: visible[i].thumbnail),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * _step,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: AppColors.sageSurface,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
                alignment: Alignment.center,
                child: Text('+$extra', style: AppTextStyles.labelSmall),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _Thumbnails._size,
      height: _Thumbnails._size,
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.card, width: 2),
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusMd,
        child: NearzyNetworkImage(
          url: url ?? '',
          width: _Thumbnails._size,
          height: _Thumbnails._size,
          semanticLabel: 'Ordered item',
        ),
      ),
    );
  }
}

/// "Today", "Yesterday", "3 days ago", then an absolute date.
String _relativeDate(DateTime when) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(when.year, when.month, when.day))
      .inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final sameYear = when.year == now.year;
  return sameYear
      ? '${when.day} ${months[when.month - 1]}'
      : '${when.day} ${months[when.month - 1]} ${when.year}';
}

/// Exposed so the detail screen shows the same phrasing as the list.
String orderRelativeDate(DateTime when) => _relativeDate(when);
