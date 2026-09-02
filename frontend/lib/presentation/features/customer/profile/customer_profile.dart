import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/image_constants.dart';
import '../../../../data/models/customer.dart';
import '../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../services/session_manager.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/nearzy_page_route.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/widgets/account_switcher_sheet.dart';
import '../../../common/widgets/shimmer_loading.dart';
import '../address/address_picker_sheet.dart';
import '../authentication/view/customer_login.dart';
import '../authentication/view_model/customer_auth_bloc.dart';
import '../location/location_picker_screen.dart';
import '../orders/view/customer_orders_screen.dart';
import '../orders/view/order_detail_screen.dart';
import '../orders/widgets/order_summary_card.dart';
import '../saved/saved_items_screen.dart';

/// How many orders the profile previews before deferring to the full list.
const int _recentOrderCount = 3;

class CustomerProfile extends StatelessWidget {
  const CustomerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerAuthBloc, CustomerAuthState>(
      builder: (context, state) {
        if (state is CustomerAuthLoadingState) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: _ProfileSkeleton(),
          );
        }

        final repository = context.read<CustomerDataRepository>();
        final Customer? customer = repository.customer;

        if (customer == null) return const _SignedOut();

        if (customer.orders == null) {
          context.read<CustomerAuthBloc>().add(CustomerDataLoadMyOrdersEvent());
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: _ProfileSkeleton(),
          );
        }

        final orders = customer.orders!;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  16,
                  AppSpacing.gutter,
                  0,
                ),
                child: _IdentityCard(
                  customer: customer,
                  onTap: () => AccountSwitcherSheet.show(context),
                ).animateEntrance(),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  16,
                  AppSpacing.gutter,
                  0,
                ),
                child: _StatsRow(
                  orderCount: orders.length,
                  savedCount: repository.favouriteProductIds.length,
                ).animateEntrance(index: 1),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sectionGap,
                  AppSpacing.gutter,
                  0,
                ),
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Orders',
                      subtitle: orders.isEmpty
                          ? 'No orders yet'
                          : '${orders.length} order${orders.length == 1 ? '' : 's'}',
                      onTap: () => _openOrders(context),
                    ).animateEntrance(index: 2),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.place_outlined,
                      title: 'Delivery addresses',
                      subtitle: 'Where your orders arrive',
                      onTap: () => AddressPickerSheet.show(
                        context,
                        mode: AddressSheetMode.manage,
                      ),
                    ).animateEntrance(index: 3),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.favorite_border_rounded,
                      title: 'Saved items',
                      subtitle: repository.favouriteProductIds.isEmpty
                          ? 'Nothing saved yet'
                          : '${repository.favouriteProductIds.length} saved',
                      onTap: () =>
                          context.pushScreen(() => const SavedItemsScreen()),
                    ).animateEntrance(index: 4),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.explore_outlined,
                      title: 'Shopping area',
                      subtitle: repository
                              .currentSelectedLocation?.shortAddress ??
                          'Everywhere',
                      onTap: () => _changeLocation(context),
                    ).animateEntrance(index: 5),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Accounts',
                      subtitle: _accountsSubtitle(),
                      onTap: () => AccountSwitcherSheet.show(context),
                    ).animateEntrance(index: 6),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sectionGap,
                  AppSpacing.gutter,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Recent orders',
                          style: AppTextStyles.sectionTitle),
                    ),
                    if (orders.length > _recentOrderCount)
                      TextButton(
                        onPressed: () => _openOrders(context),
                        child: Text('See all', style: AppTextStyles.link),
                      ),
                  ],
                ),
              ),
            ),

            if (orders.isEmpty)
              const SliverToBoxAdapter(child: _NoOrders())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                // Only the most recent few — the full history lives behind
                // the Orders tile, so this stays a glance rather than a list
                // that grows without bound on the profile.
                sliver: SliverList.separated(
                  itemCount: orders.length < _recentOrderCount
                      ? orders.length
                      : _recentOrderCount,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => OrderSummaryCard(
                    order: orders[index],
                    onTap: () => _openOrder(context, orders[index].id),
                  ).animateEntrance(index: index),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.bottomNavInset),
            ),
          ],
        );
      },
    );
  }

  /// Reloads history on the way back, so a status the shop advanced while
  /// the customer was away shows up without a manual pull-to-refresh.
  Future<void> _openOrders(BuildContext context) async {
    final bloc = context.read<CustomerAuthBloc>();
    await context.pushScreen(() => const CustomerOrdersScreen());
    bloc.add(CustomerDataLoadMyOrdersEvent());
  }

  Future<void> _openOrder(BuildContext context, int orderId) async {
    final bloc = context.read<CustomerAuthBloc>();
    await context.pushScreen(() => OrderDetailScreen(orderId: orderId));
    bloc.add(CustomerDataLoadMyOrdersEvent());
  }

  Future<void> _changeLocation(BuildContext context) async {
    final repository = context.read<CustomerDataRepository>();
    final picked = await context.pushModal<dynamic>(
      () => LocationPickerScreen(initial: repository.currentSelectedLocation),
    );
    if (picked == null || !context.mounted) return;
    repository.setLocation(picked);
  }

  /// Says how many identities this device holds, so the tile reads as a
  /// switcher rather than a settings dead end.
  String _accountsSubtitle() {
    final others = SessionManager.instance.otherAccounts.length;
    if (others == 0) return 'Add an account, or sign out';
    return others == 1
        ? '1 other account — switch or sign out'
        : '$others other accounts — switch or sign out';
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.985,
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.inkGradient,
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.inkSoft,
              backgroundImage:
                  AssetImage(ImageConstants.defaultProfileImage),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.user.username,
                  style:
                      AppTextStyles.heading3.copyWith(color: AppColors.paper),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  customer.user.email,
                  style: AppTextStyles.caption.copyWith(color: AppColors.sage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.inkSoft,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    size: 14, color: AppColors.lime),
                const SizedBox(width: 4),
                Text('Switch',
                    style:
                        AppTextStyles.micro.copyWith(color: AppColors.lime)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.orderCount, required this.savedCount});

  final int orderCount;
  final int savedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(value: '$orderCount', label: 'Orders')),
        const SizedBox(width: AppSpacing.gridGap),
        Expanded(child: _Stat(value: '$savedCount', label: 'Saved')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.priceMedium),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const tint = AppColors.ink;

    return PressableScale(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.sageSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.labelMedium.copyWith(color: tint)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _NoOrders extends StatelessWidget {
  const _NoOrders();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: 28,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 28, color: AppColors.sage),
          ),
          const SizedBox(height: 16),
          Text('No orders yet', style: AppTextStyles.heading4),
          const SizedBox(height: 6),
          Text(
            'Orders you place with local shops show up here.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animateEntrance();
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerLoading.listRows(count: 1, height: 104),
        const SizedBox(height: 16),
        ShimmerLoading.listRows(count: 3, height: 68),
      ],
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

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
              child: const Icon(Icons.person_outline_rounded,
                  size: 34, color: AppColors.sage),
            ).animateEntrance(),
            const SizedBox(height: 20),
            Text('Not signed in', style: AppTextStyles.heading2)
                .animateEntrance(index: 1),
            const SizedBox(height: 8),
            Text(
              'Sign in for your orders, saved items and addresses.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ).animateEntrance(index: 2),
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              child: ElevatedButton(
                onPressed: () =>
                    context.pushScreen(() => const CustomerLogin()),
                child: const Text('Sign in or create account'),
              ),
            ).animateEntrance(index: 3),
            // Signing out of one account leaves the others on the device, so
            // getting back into them must not mean retyping a password.
            if (SessionManager.instance.accounts.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: 240,
                child: TextButton(
                  onPressed: () => AccountSwitcherSheet.show(context),
                  child: const Text('Use a saved account'),
                ),
              ).animateEntrance(index: 4),
            ],
          ],
        ),
      ),
    );
  }
}
