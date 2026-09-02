import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/order.dart';
import '../../../../data/repositories/shop/shop_data_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/money.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/widgets/nearzy_network_image.dart';
import '../../../common/widgets/shimmer_loading.dart';
import '../../customer/orders/widgets/order_status_chip.dart';
import '../product_upload/view_model/shop_bloc.dart';

/// The shop's order book.
///
/// Each order arrives already narrowed to this shop's own line items, with
/// the customer's contact details attached so it can be fulfilled. Advancing
/// status goes through the backend, which permits only the next step — so the
/// button offers exactly one destination rather than a free-form picker.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    if (context.read<ShopDataRepository>().myOrders.isEmpty) {
      context.read<ShopBloc>().add(ShopLoadMyOrdersEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Orders')),
      body: BlocConsumer<ShopBloc, ShopState>(
        listener: (context, state) {
          if (state is ShopErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.customException.message,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textOnInk),
                ),
                backgroundColor: AppColors.ink,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ShopLoadingState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: ShimmerLoading.listRows(count: 4, height: 176),
            );
          }

          final orders = context.read<ShopDataRepository>().myOrders;
          if (orders.isEmpty) return const _NoOrders();

          return RefreshIndicator(
            color: AppColors.ink,
            backgroundColor: AppColors.card,
            onRefresh: () async =>
                context.read<ShopBloc>().add(ShopLoadMyOrdersEvent()),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.bottomNavInset,
              ),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) =>
                  ShopOrderCard(order: orders[index])
                      .animateEntrance(index: index),
            ),
          );
        },
      ),
    );
  }
}

class ShopOrderCard extends StatelessWidget {
  const ShopOrderCard({super.key, required this.order});

  final Order order;

  Future<void> _call(BuildContext context) async {
    final number = order.customer?.phoneNumber ?? '';
    if (number.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the dialler',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textOnInk)),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirm(
    BuildContext context, {
    required OrderStatus target,
    required String question,
    required String action,
    bool destructive = false,
  }) async {
    final bloc = context.read<ShopBloc>();
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(question, style: AppTextStyles.heading4),
        content: Text(
          'Order ${order.orderNumber}',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              action,
              style: AppTextStyles.labelLarge.copyWith(
                color: destructive ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
    if (agreed != true) return;

    HapticFeedback.lightImpact();
    bloc.add(ShopUpdateOrderStatus(orderId: order.id, status: target));
  }

  @override
  Widget build(BuildContext context) {
    final next = order.status.next;
    final customer = order.customer;

    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.name.isNotEmpty == true
                          ? customer!.name
                          : 'Customer',
                      style: AppTextStyles.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(order.orderNumber, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text(Money.exact(order.totalAmountPaise),
                  style: AppTextStyles.priceSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              OrderStatusChip(status: order.status),
              const SizedBox(width: AppSpacing.sm),
              PaymentStatusChip(status: order.paymentStatus),
            ],
          ),
          Divider(height: 24, color: AppColors.line),

          for (final line in order.items) ...[
            _Line(line: line),
            const SizedBox(height: AppSpacing.sm),
          ],

          if (order.shippingAddressText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined,
                    size: 15, color: AppColors.sage),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(order.shippingAddressText,
                      style: AppTextStyles.caption),
                ),
              ],
            ),
          ],

          if (next != null || customer?.phoneNumber.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                if (customer?.phoneNumber.isNotEmpty == true)
                  OutlinedButton.icon(
                    onPressed: () => _call(context),
                    icon: const Icon(Icons.call_outlined, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                    ),
                  ),
                const Spacer(),
                if (!order.status.isTerminal)
                  TextButton(
                    onPressed: () => _confirm(
                      context,
                      target: OrderStatus.cancelled,
                      question: 'Cancel this order?',
                      action: 'Cancel order',
                      destructive: true,
                    ),
                    child: Text('Cancel',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.error)),
                  ),
                if (next != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  // Lime marks the single highest-intent action on the card.
                  ElevatedButton(
                    onPressed: () => _confirm(
                      context,
                      target: next,
                      question: 'Mark as ${next.label.toLowerCase()}?',
                      action: 'Mark ${next.label.toLowerCase()}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.ink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                    ),
                    child: Text(
                      next.label,
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.ink),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusSm,
          child: NearzyNetworkImage(
            url: line.thumbnail ?? '',
            width: 40,
            height: 40,
            semanticLabel: line.name,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.name,
                  style: AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                line.sku.isEmpty
                    ? '${line.quantity} × ${Money.exact(line.unitPricePaise)}'
                    : '${line.sku} · ${line.quantity} × ${Money.exact(line.unitPricePaise)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        Text(Money.exact(line.lineTotalPaise), style: AppTextStyles.labelMedium),
      ],
    );
  }
}

class _NoOrders extends StatelessWidget {
  const _NoOrders();

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
              child: const Icon(Icons.receipt_long_outlined,
                  size: 34, color: AppColors.sage),
            ).animateEntrance(),
            const SizedBox(height: AppSpacing.lg),
            Text('No orders yet', style: AppTextStyles.heading3)
                .animateEntrance(index: 1),
            const SizedBox(height: 6),
            Text(
              'Orders customers place with your shop show up here.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ).animateEntrance(index: 2),
          ],
        ),
      ),
    );
  }
}
