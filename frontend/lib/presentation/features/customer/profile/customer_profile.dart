import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/bottom_navbar_items.dart';
import '../../../../constants/image_constants.dart';
import '../../../../data/models/customer.dart';
import '../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/nearzy_page_route.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/widgets/shimmer_loading.dart';
import '../../shop/orders/orders_screen.dart';
import '../authentication/view/customer_login.dart';
import '../authentication/view_model/customer_auth_bloc.dart';
import '../location/location_picker_screen.dart';
import '../saved/saved_items_screen.dart';

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
                child: _IdentityCard(customer: customer).animateEntrance(),
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
                      icon: Icons.favorite_border_rounded,
                      title: 'Saved items',
                      subtitle: repository.favouriteProductIds.isEmpty
                          ? 'Nothing saved yet'
                          : '${repository.favouriteProductIds.length} saved',
                      onTap: () =>
                          context.pushScreen(() => const SavedItemsScreen()),
                    ).animateEntrance(index: 2),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.place_outlined,
                      title: 'Shopping area',
                      subtitle: repository
                              .currentSelectedLocation?.shortAddress ??
                          'Everywhere',
                      onTap: () => _changeLocation(context),
                    ).animateEntrance(index: 3),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      subtitle: 'You can sign back in anytime',
                      destructive: true,
                      onTap: () => _confirmSignOut(context),
                    ).animateEntrance(index: 4),
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
                child: Text('Your orders', style: AppTextStyles.sectionTitle),
              ),
            ),

            if (orders.isEmpty)
              const SliverToBoxAdapter(child: _NoOrders())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                sliver: SliverList.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) => OrderCard(
                    order: orders[index],
                    role: Roles.ROLE_CUSTOMER,
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

  Future<void> _changeLocation(BuildContext context) async {
    final repository = context.read<CustomerDataRepository>();
    final picked = await context.pushModal<dynamic>(
      () => LocationPickerScreen(initial: repository.currentSelectedLocation),
    );
    if (picked == null || !context.mounted) return;
    repository.setLocation(picked);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<CustomerAuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(
          'Your bag and saved items stay on this device.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign out',
                style: AppTextStyles.link.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(CustomerLogoutEvent());
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
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
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? AppColors.error : AppColors.ink;

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
              decoration: BoxDecoration(
                color: destructive
                    ? AppColors.errorSurface
                    : AppColors.sageSurface,
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
          ],
        ),
      ),
    );
  }
}
