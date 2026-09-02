import 'package:flutter/material.dart';

import '../../../../../data/models/order.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';

/// Status pill for an order, in the status's own semantic colour.
///
/// Deliberately not lime: the accent marks what the user should act on, and
/// an order's state is information, not an action.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status, this.compact = false});

  final OrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : AppSpacing.md,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.surface,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 11 : 13, color: status.color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            status.label,
            style: (compact ? AppTextStyles.labelSmall : AppTextStyles.labelMedium)
                .copyWith(color: status.color),
          ),
        ],
      ),
    );
  }
}

/// Shown beside the status only when payment needs the user's attention —
/// a paid order says so on its receipt, not as a warning badge.
class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    if (!status.needsAttention) return const SizedBox.shrink();

    final color = status == PaymentStatus.failed
        ? OrderStatus.cancelled.color
        : OrderStatus.shipped.color;
    final surface = status == PaymentStatus.failed
        ? OrderStatus.cancelled.surface
        : OrderStatus.shipped.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
