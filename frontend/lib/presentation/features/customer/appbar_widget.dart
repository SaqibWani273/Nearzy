import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/customer.dart';
import '../../../data/models/shop_model/shop_model1.dart';
import '../../../data/repositories/customer/customer_data_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../common/animations/nearzy_page_route.dart';
import '../../common/animations/pressable_scale.dart';
import '../../common/widgets/nearzy_logo.dart';
import 'cart/cart_screen.dart';
import 'dashboard/view_model/customer_data_bloc.dart';
import 'location/location_picker_screen.dart';

/// Customer app bar: brand mark, the current location (tappable), and cart.
///
/// The location chip is the app bar's reason to exist — on a hyperlocal
/// marketplace "where am I shopping" is persistent context, not a setting
/// buried in a menu.
class AppBarWidget extends StatelessWidget {
  const AppBarWidget({super.key});

  Future<void> _changeLocation(BuildContext context) async {
    final repo = context.read<CustomerDataRepository>();
    final bloc = context.read<CustomerDataBloc>();

    final picked = await context.pushModal<LocationInfo>(
      () => LocationPickerScreen(initial: repo.currentSelectedLocation),
    );
    if (picked == null) return;
    bloc.add(SetCustomerLocationEvent(location: picked));
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      toolbarHeight: 64,
      backgroundColor: AppColors.paper,
      leading: Builder(
        builder: (context) => IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded, size: 22),
        ),
      ),
      title: const NearzyLogo(size: 26),
      actions: [
        BlocBuilder<CustomerDataBloc, CustomerDataState>(
          builder: (context, state) {
            final repo = context.read<CustomerDataRepository>();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _LocationChip(
                    label: repo.currentSelectedLocation?.shortAddress ??
                        'Everywhere',
                    busy: state is CustomerDataLoadedState &&
                        state.isChangingLocation == true,
                    onTap: () => _changeLocation(context),
                  ),
                ),
                _CartIconButton(customer: repo.customer),
                const SizedBox(width: 6),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Change location',
      child: PressableScale(
        onTap: onTap,
        scale: 0.94,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 168),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppSpacing.borderRadiusFull,
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: Motion.duration(context, Motion.quick),
                child: busy
                    ? const SizedBox(
                        key: ValueKey('busy'),
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.sageDeep,
                        ),
                      )
                    : const Icon(
                        Icons.place_rounded,
                        key: ValueKey('idle'),
                        size: 14,
                        color: AppColors.sageDeep,
                      ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Icon(Icons.expand_more_rounded,
                  size: 15, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  const _CartIconButton({required this.customer});

  final Customer? customer;

  @override
  Widget build(BuildContext context) {
    final count = customer?.cartItems?.length ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: () => context.pushScreen(() => CartScreen()),
          tooltip: 'Cart',
          icon: const Icon(Icons.shopping_bag_outlined, size: 22),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 8,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Motion.duration(context, Motion.base),
              curve: Motion.spring,
              builder: (_, value, child) =>
                  Transform.scale(scale: value.clamp(0.0, 1.4), child: child),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: AppSpacing.borderRadiusFull,
                  border: Border.all(color: AppColors.paper, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                child: Center(
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: AppTextStyles.badge.copyWith(color: AppColors.lime),
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
