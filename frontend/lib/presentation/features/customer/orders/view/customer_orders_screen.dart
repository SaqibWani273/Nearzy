import 'package:flutter/material.dart';

import '../../../../../data/models/order.dart';
import '../../../../../services/api_service.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_motion.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/animations/entrance.dart';
import '../../../../common/animations/nearzy_page_route.dart';
import '../../../../common/widgets/shimmer_loading.dart';
import '../widgets/order_summary_card.dart';
import 'order_detail_screen.dart';

/// Full order history, filterable by status.
///
/// The profile screen shows only the most recent few; this is the "See all"
/// destination and the place a customer comes back to for a receipt.
class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

/// Groups the five backend statuses into the three questions a customer
/// actually asks: what's coming, what arrived, what fell through.
enum _Filter {
  all('All', null),
  active('Active', 'PLACED,CONFIRMED,SHIPPED'),
  delivered('Delivered', 'DELIVERED'),
  cancelled('Cancelled', 'CANCELLED');

  const _Filter(this.label, this.query);

  final String label;
  final String? query;
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  _Filter _filter = _Filter.all;
  late Future<List<Order>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _load();
  }

  Future<List<Order>> _load() =>
      ApiService.fetchCustomerOrders(status: _filter.query, limit: 50);

  void _select(_Filter filter) {
    if (_filter == filter) return;
    setState(() {
      _filter = filter;
      _orders = _load();
    });
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _orders = future);
    await future.catchError((_) => <Order>[]);
  }

  /// Re-reads the list after the detail screen, so a status the shop advanced
  /// while the customer was looking is reflected on the way back.
  Future<void> _openDetail(Order order) async {
    await context.pushScreen(() => OrderDetailScreen(orderId: order.id));
    if (!mounted) return;
    setState(() => _orders = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Your orders')),
      body: Column(
        children: [
          _FilterBar(selected: _filter, onSelect: _select),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.ink,
              backgroundColor: AppColors.card,
              child: FutureBuilder<List<Order>>(
                future: _orders,
                builder: (context, snapshot) {
                  final waiting =
                      snapshot.connectionState == ConnectionState.waiting;

                  // Cross-fade rather than cut, per the motion language.
                  return AnimatedSwitcher(
                    duration: Motion.base,
                    switchInCurve: Motion.easeOut,
                    child: waiting
                        ? const _OrdersSkeleton()
                        : snapshot.hasError
                            ? _OrdersError(
                                message: _messageFor(snapshot.error),
                                onRetry: _refresh,
                              )
                            : _OrdersList(
                                orders: snapshot.data ?? const [],
                                filter: _filter,
                                onOpen: _openDetail,
                              ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _messageFor(Object? error) {
  final text = error?.toString() ?? '';
  // CustomException.toString() is noisy; its message is the useful half.
  final match = RegExp(r'message:\s*(.+?)[,)]').firstMatch(text);
  return match?.group(1) ?? 'Something went wrong loading your orders.';
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelect});

  final _Filter selected;
  final ValueChanged<_Filter> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: 12,
        ),
        itemCount: _Filter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = _Filter.values[index];
          final active = filter == selected;
          return GestureDetector(
            onTap: () => onSelect(filter),
            child: AnimatedContainer(
              duration: Motion.quick,
              curve: Motion.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.card,
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(
                  color: active ? AppColors.ink : AppColors.line,
                ),
              ),
              child: Text(
                filter.label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: active ? AppColors.textOnInk : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.filter,
    required this.onOpen,
  });

  final List<Order> orders;
  final _Filter filter;
  final ValueChanged<Order> onOpen;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return _NoOrdersYet(filter: filter);

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        4,
        AppSpacing.gutter,
        AppSpacing.bottomNavInset,
      ),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => OrderSummaryCard(
        order: orders[index],
        onTap: () => onOpen(orders[index]),
      ).animateEntrance(index: index),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        4,
        AppSpacing.gutter,
        0,
      ),
      children: [ShimmerLoading.listRows(count: 5, height: 132)],
    );
  }
}

class _NoOrdersYet extends StatelessWidget {
  const _NoOrdersYet({required this.filter});

  final _Filter filter;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (filter) {
      _Filter.all => (
          'No orders yet',
          'Orders you place with local shops show up here.',
        ),
      _Filter.active => (
          'Nothing on its way',
          'Orders being prepared or shipped appear here.',
        ),
      _Filter.delivered => (
          'Nothing delivered yet',
          'Once an order arrives, it moves here.',
        ),
      _Filter.cancelled => (
          'No cancelled orders',
          'Good — nothing has fallen through.',
        ),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            60,
            AppSpacing.gutter,
            0,
          ),
          child: Column(
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
              Text(title, style: AppTextStyles.heading3)
                  .animateEntrance(index: 1),
              const SizedBox(height: 6),
              Text(
                body,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ).animateEntrance(index: 2),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            60,
            AppSpacing.gutter,
            0,
          ),
          child: Column(
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
              Text("Couldn't load your orders",
                      style: AppTextStyles.heading3)
                  .animateEntrance(index: 1),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ).animateEntrance(index: 2),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: onRetry,
                child: Text('Try again', style: AppTextStyles.link),
              ).animateEntrance(index: 3),
            ],
          ),
        ),
      ],
    );
  }
}
