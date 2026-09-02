import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../data/models/address.dart';
import '../../../../../data/models/order.dart';
import '../../../../../services/api_service.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_motion.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../utils/money.dart';
import '../../../../common/animations/entrance.dart';
import '../../../../common/widgets/nearzy_network_image.dart';
import '../../../../common/widgets/shimmer_loading.dart';
import '../widgets/order_status_chip.dart';
import '../widgets/order_summary_card.dart' show orderRelativeDate;

/// One order in full: a progress trail, the items, the delivery address, and
/// a receipt whose figures reconcile.
///
/// Always re-fetches rather than taking the list's copy, so the status shown
/// is current even if the shop advanced it minutes ago.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order> _order;

  @override
  void initState() {
    super.initState();
    _order = ApiService.fetchCustomerOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Order')),
      body: FutureBuilder<Order>(
        future: _order,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;

          return AnimatedSwitcher(
            duration: Motion.base,
            switchInCurve: Motion.easeOut,
            child: waiting
                ? const _DetailSkeleton()
                : snapshot.hasError || !snapshot.hasData
                    ? _DetailError(
                        onRetry: () => setState(() {
                          _order = ApiService.fetchCustomerOrder(widget.orderId);
                        }),
                      )
                    : _Detail(order: snapshot.data!),
          );
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.xxxl,
      ),
      children: [
        _Header(order: order).animateEntrance(),
        const SizedBox(height: AppSpacing.xl),
        if (order.status != OrderStatus.cancelled)
          _ProgressTrail(status: order.status).animateEntrance(index: 1),
        if (order.status != OrderStatus.cancelled)
          const SizedBox(height: AppSpacing.xl),
        _Section(
          title: order.itemCount == 1 ? '1 item' : '${order.itemCount} items',
          index: 2,
          child: Column(
            children: [
              for (var i = 0; i < order.items.length; i++) ...[
                if (i > 0) Divider(height: 24, color: AppColors.line),
                _ItemRow(line: order.items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        if (order.shippingAddress != null)
          _Section(
            title: 'Delivering to',
            index: 3,
            child: _AddressBlock(address: order.shippingAddress!),
          ),
        if (order.shippingAddress != null)
          const SizedBox(height: AppSpacing.base),
        _Section(
          title: 'Payment',
          index: 4,
          child: _Receipt(order: order),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OrderStatusChip(status: order.status),
            const SizedBox(width: AppSpacing.sm),
            PaymentStatusChip(status: order.paymentStatus),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(Money.exact(order.totalAmountPaise),
            style: AppTextStyles.priceLarge),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                order.placedAt == null
                    ? 'Order ${order.orderNumber}'
                    : 'Placed ${orderRelativeDate(order.placedAt!).toLowerCase()}'
                        ' · ${order.orderNumber}',
                style: AppTextStyles.caption,
              ),
            ),
            // The order number is what support asks for, so make it copyable.
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: order.orderNumber));
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order number copied',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textOnInk)),
                    backgroundColor: AppColors.ink,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              color: AppColors.textTertiary,
              tooltip: 'Copy order number',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}

/// The four forward states as a connected trail. Cancelled orders skip it —
/// a progress bar for something that stopped is a contradiction.
class _ProgressTrail extends StatelessWidget {
  const _ProgressTrail({required this.status});

  final OrderStatus status;

  static const _steps = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final reached = _steps.indexOf(status);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppSpacing.shadowSoft,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: i <= reached ? AppColors.ink : AppColors.line,
                ),
              ),
            _Step(
              step: _steps[i],
              done: i <= reached,
              current: i == reached,
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.step, required this.done, required this.current});

  final OrderStatus step;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: Motion.base,
          curve: Motion.spring,
          width: current ? 34 : 28,
          height: current ? 34 : 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.ink : AppColors.card,
            border: Border.all(
              color: done ? AppColors.ink : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Icon(
            step.icon,
            size: current ? 17 : 14,
            color: done ? AppColors.lime : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        // Fixed width keeps the trail's spacing even as labels differ in
        // length; the text is allowed to wrap rather than the box to grow.
        SizedBox(
          width: 62,
          child: Text(
            step.label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: done ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    required this.index,
  });

  final String title;
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading4),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppSpacing.borderRadiusXl,
            boxShadow: AppSpacing.shadowSoft,
          ),
          child: child,
        ),
      ],
    ).animateEntrance(index: index);
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusMd,
          child: NearzyNetworkImage(
            url: line.thumbnail ?? '',
            width: 56,
            height: 56,
            semanticLabel: line.name,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.name,
                  style: AppTextStyles.labelLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(
                [
                  if (line.shopName.isNotEmpty) line.shopName,
                  '${line.quantity} × ${Money.exact(line.unitPricePaise)}',
                ].join(' · '),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(Money.exact(line.lineTotalPaise),
            style: AppTextStyles.priceSmall),
      ],
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.address});

  final Address address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.place_outlined, size: 18, color: AppColors.sage),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (address.label.isNotEmpty)
                Text(address.label, style: AppTextStyles.labelLarge),
              if (address.label.isNotEmpty) const SizedBox(height: 2),
              Text(address.streetLine, style: AppTextStyles.bodySmall),
              Text(address.regionLine, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Subtotal − discount = total, exactly as the DTO guarantees.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Line(label: 'Subtotal', value: Money.exact(order.subtotalPaise)),
        if (order.hasDiscount) ...[
          const SizedBox(height: AppSpacing.sm),
          _Line(
            label: 'Discount',
            value: Money.negated(order.discountAmountPaise),
            valueColor: AppColors.success,
          ),
        ],
        Divider(height: 24, color: AppColors.line),
        Row(
          children: [
            Expanded(child: Text('Total', style: AppTextStyles.heading4)),
            Text(Money.exact(order.totalAmountPaise),
                style: AppTextStyles.priceMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(order.paymentStatus.label,
                  style: AppTextStyles.caption),
            ),
          ],
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.gutter),
      children: [
        ShimmerLoading.line(width: 120, height: 28),
        const SizedBox(height: AppSpacing.md),
        ShimmerLoading.line(width: 160, height: 34),
        const SizedBox(height: AppSpacing.xl),
        ShimmerLoading.listRows(count: 1, height: 92),
        const SizedBox(height: AppSpacing.xl),
        ShimmerLoading.listRows(count: 2, height: 88),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line, width: 1.5),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 34, color: AppColors.sage),
            ).animateEntrance(),
            const SizedBox(height: AppSpacing.lg),
            Text("Couldn't load this order", style: AppTextStyles.heading3)
                .animateEntrance(index: 1),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onRetry,
              child: Text('Try again', style: AppTextStyles.link),
            ).animateEntrance(index: 2),
          ],
        ),
      ),
    );
  }
}
