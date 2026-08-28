import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/customer/customer_data_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'cart/cart_screen.dart';
import 'dashboard/view_model/customer_data_bloc.dart';

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: AppColors.card,
      leading: Builder(
        builder: (context) => IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu_rounded, size: 24),
        ),
      ),
      title: BlocBuilder<CustomerDataBloc, CustomerDataState>(
        builder: (context, state) {
          return Text(
            'Nearzy',
            style: AppTextStyles.brand.copyWith(fontSize: 18),
          );
        },
      ),
      actions: [
        BlocBuilder<CustomerDataBloc, CustomerDataState>(
          builder: (context, state) {
            Customer? customer = context
                .read<CustomerDataRepository>()
                .customer;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location indicator
                if (state is CustomerDataLoadedState)
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            context
                                        .read<CustomerDataRepository>()
                                        .currentSelectedLocation ==
                                    null
                                ? 'Global'
                                : context
                                      .read<CustomerDataRepository>()
                                      .currentSelectedLocation!
                                      .shortAddress,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Notifications
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_outlined,
                    size: 23,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Cart with badge
                _CartIconButton(customer: customer),
                const SizedBox(width: 4),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CartIconButton extends StatelessWidget {
  final Customer? customer;
  const _CartIconButton({required this.customer});

  @override
  Widget build(BuildContext context) {
    final count = customer?.cartItems?.length ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => CartScreen()));
          },
          icon: const Icon(
            Icons.shopping_bag_outlined,
            size: 23,
            color: AppColors.textPrimary,
          ),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppSpacing.durationNormal,
              curve: AppSpacing.curveSnap,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppSpacing.borderRadiusFull,
                  border: Border.all(color: AppColors.card, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: AppTextStyles.badge.copyWith(fontSize: 9),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Legacy CartIcon — kept for backwards compat.
class CartIcon extends StatelessWidget {
  const CartIcon({super.key, required this.customer});
  final Customer? customer;

  @override
  Widget build(BuildContext context) => _CartIconButton(customer: customer);
}
