import 'package:flutter/material.dart';

import '../../../../data/models/shop_dashboard.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/widgets/shimmer_loading.dart';
import '../inventory/widgets/product_edit_sheet.dart';
import 'widgets/triage_card.dart';

/// The shop owner's home.
///
/// Replaces opening onto an inventory list. An inventory list answers "what do
/// I sell?", which the owner already knows; this answers "what needs me right
/// now?" — orders waiting to be packed, stock about to run out — and every
/// card resolves in a single tap.
class ShopDashboardScreen extends StatefulWidget {
  const ShopDashboardScreen({super.key, this.onOpenOrders});

  /// Jumps the shell to the Orders tab. Supplied by the nav shell rather than
  /// pushing a route, so the bottom bar stays in sync with what is on screen.
  final VoidCallback? onOpenOrders;

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  late Future<ShopDashboard> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = ApiService.fetchShopDashboard();
  }

  Future<void> _refresh() async {
    final next = ApiService.fetchShopDashboard();
    setState(() => _dashboard = next);
    // Swallowed deliberately: the FutureBuilder below renders the failure.
    // Letting it escape here would also trip RefreshIndicator's own handler.
    await next.catchError((_) => throw _Handled());
  }

  /// Marks an alert resolved, then reloads so the counts move with it.
  Future<void> _dismiss(ShopAlert alert) async {
    try {
      await ApiService.setAlertStatus(alert.id, 'RESOLVED');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not dismiss that alert.')),
      );
      return;
    }
    if (mounted) await _refresh();
  }

  /// Opens the stock/price sheet over the dashboard, then refreshes — a
  /// restock should visibly clear the alert that prompted it.
  Future<void> _openProduct(int productId) async {
    final changed = await ProductEditSheet.show(context, productId: productId);
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.ink,
          backgroundColor: AppColors.card,
          child: FutureBuilder<ShopDashboard>(
            future: _dashboard,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _DashboardSkeleton();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _DashboardError(onRetry: _refresh);
              }
              return _DashboardBody(
                data: snapshot.data!,
                onOpenOrders: widget.onOpenOrders,
                onDismiss: _dismiss,
                onOpenProduct: _openProduct,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sentinel so `_refresh` can swallow a failure the FutureBuilder will render.
class _Handled implements Exception {}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.onOpenOrders,
    required this.onDismiss,
    required this.onOpenProduct,
  });

  final ShopDashboard data;
  final VoidCallback? onOpenOrders;
  final Future<void> Function(ShopAlert) onDismiss;
  final Future<void> Function(int) onOpenProduct;

  @override
  Widget build(BuildContext context) {
    // Orders first: a customer is waiting on those, which outranks stock that
    // is merely running low.
    final cards = <Widget>[
      if (data.pendingOrders > 0)
        TriageCard(
          icon: Icons.inventory_rounded,
          title: data.pendingOrders == 1
              ? '1 order waiting'
              : '${data.pendingOrders} orders waiting',
          subtitle: 'Confirm and pack them so customers know they are on the way.',
          accent: AppColors.info,
          surface: AppColors.infoSurface,
          actionLabel: 'Open orders',
          onTap: onOpenOrders,
        ),
      ...data.alerts.map(
        (alert) => TriageCard(
          icon: alert.type.icon,
          title: alert.title,
          subtitle: alert.body,
          accent: alert.severity.color,
          surface: alert.severity.surface,
          actionLabel:
              alert.product == null ? 'Review' : alert.type.actionLabel,
          onTap: alert.product == null
              ? null
              : () => onOpenProduct(alert.product!.id),
          onDismiss: () => onDismiss(alert),
        ),
      ),
    ];

    return CustomScrollView(
      // Always scrollable, so pull-to-refresh still works on a clear board.
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _Greeting(data: data)),
        if (cards.isEmpty)
          SliverToBoxAdapter(child: _AllClear(inventory: data.inventory))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            sliver: SliverList.separated(
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) =>
                  cards[index].animateEntrance(index: index),
            ),
          ),
        SliverToBoxAdapter(child: _InventoryStrip(inventory: data.inventory)),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.bottomNavInset),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.data});

  final ShopDashboard data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xl,
        AppSpacing.gutter,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today', style: AppTextStyles.overline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.shopName.isEmpty ? 'Your shop' : data.shopName,
            style: AppTextStyles.heading1,
          ),
          if (!data.isVerified) ...[
            const SizedBox(height: AppSpacing.md),
            _VerificationNotice(status: data.verificationStatus),
          ],
        ],
      ),
    );
  }
}

/// An unverified shop is invisible to customers, which explains an otherwise
/// baffling "no orders ever" — so it is stated plainly rather than left to be
/// discovered.
class _VerificationNotice extends StatelessWidget {
  const _VerificationNotice({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'REJECTED';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: rejected ? AppColors.errorSurface : AppColors.warningSurface,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Icon(
            rejected
                ? Icons.error_outline_rounded
                : Icons.hourglass_top_rounded,
            size: 18,
            color: rejected ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              rejected
                  ? 'Your application was rejected. Contact support to reapply.'
                  : 'Your shop is awaiting verification and is not yet visible to customers.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllClear extends StatelessWidget {
  const _AllClear({required this.inventory});

  final InventorySummary inventory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xxl,
        AppSpacing.gutter,
        AppSpacing.lg,
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
            child: const Icon(
              Icons.check_rounded,
              size: 36,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text('Nothing needs you', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No orders waiting and no stock running low. '
            '${inventory.total} ${inventory.total == 1 ? 'product' : 'products'} listed.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animateEntrance();
  }
}

/// The quieter counts — context, not tasks, so they sit below the triage list.
class _InventoryStrip extends StatelessWidget {
  const _InventoryStrip({required this.inventory});

  final InventorySummary inventory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sectionGap,
        AppSpacing.gutter,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.base,
        ),
        decoration: BoxDecoration(
          color: AppColors.sageSurface,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        child: Row(
          children: [
            _Stat(label: 'Listed', value: inventory.total),
            _Divider(),
            _Stat(label: 'Sold out', value: inventory.outOfStock),
            _Divider(),
            _Stat(label: 'Hidden', value: inventory.unavailable),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Counts settle rather than snapping, per the app's number-transition
          // rule.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: Motion.duration(context, Motion.slow),
            curve: Motion.easeOut,
            builder: (context, v, _) =>
                Text('${v.round()}', style: AppTextStyles.heading3),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: AppColors.line,
      );
}

class _DashboardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xl,
        AppSpacing.gutter,
        0,
      ),
      children: [
        ShimmerLoading.line(width: 80, height: 10),
        const SizedBox(height: AppSpacing.sm),
        ShimmerLoading.line(width: 200, height: 28),
        const SizedBox(height: AppSpacing.xl),
        // Mirrors the real card silhouette — a skeleton of a different shape
        // reads as a layout jump when the content lands.
        ShimmerLoading.listRows(count: 3, height: 116),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.massive,
      ),
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line, width: 1.5),
          ),
          child: const Icon(
            Icons.cloud_off_rounded,
            size: 34,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Center(
          child: Text("Couldn't load your dashboard",
              style: AppTextStyles.heading3),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            'Check your connection and try again.',
            style: AppTextStyles.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text('Retry', style: AppTextStyles.link),
          ),
        ),
      ],
    );
  }
}
