import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/cart.dart';
import '../../../../data/models/customer.dart';
import '../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/nearzy_page_route.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/screens/error_screen.dart';
import '../../../common/widgets/nearzy_network_image.dart';
import '../../../common/widgets/shimmer_loading.dart';
import '../authentication/view/customer_login.dart';
import '../checkout/checkout_screen.dart';
import '../dashboard/view_model/customer_data_bloc.dart';
import '../product/view/product_details_screen.dart';
import 'widgets/empty_cart_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Customer? customer;
  bool isCartEmpty = false;
  List<CartItemDetails> cartItemDetailsList = [];

  @override
  void initState() {
    super.initState();
    final repository = context.read<CustomerDataRepository>();
    customer = repository.customer;
    cartItemDetailsList = repository.cartItemDetails;

    if (customer != null) {
      isCartEmpty = _checkIsCartEmpty(customer);
      if (!isCartEmpty && cartItemDetailsList.isEmpty) {
        context.read<CustomerDataBloc>().add(
              CustomerDataFetchCartItemDetailsEvent(
                cartItems: customer!.cartItems!,
              ),
            );
      }
    }
  }

  bool _checkIsCartEmpty(Customer? customer) =>
      customer == null ||
      customer.cartItems == null ||
      customer.cartItems!.isEmpty;

  Future<void> _login() async {
    await context.pushScreen(() => const CustomerLogin());
    if (!mounted) return;

    customer = context.read<CustomerDataRepository>().customer;
    if (customer != null) {
      isCartEmpty = _checkIsCartEmpty(customer);
      if (!isCartEmpty) {
        context.read<CustomerDataBloc>().add(
              CustomerDataFetchCartItemDetailsEvent(
                cartItems: customer!.cartItems!,
              ),
            );
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: BlocBuilder<CustomerDataBloc, CustomerDataState>(
        builder: (context, state) {
          final repository = context.read<CustomerDataRepository>();
          customer = repository.customer;

          if (customer == null) {
            return _NotLoggedIn(onLogin: _login);
          }

          if (state is CustomerDataFetchingCartItemDetailsState) {
            return const Padding(
              padding: EdgeInsets.only(top: 80),
              child: _CartSkeleton(),
            );
          }

          if (state is CustomerDataCartErrorState) {
            return ErrorScreen(
              customException: state.error,
              onTryAgainPressed: () => context.read<CustomerDataBloc>().add(
                    CustomerDataFetchCartItemDetailsEvent(
                      cartItems: customer!.cartItems!,
                    ),
                  ),
            );
          }

          cartItemDetailsList = repository.cartItemDetails;
          isCartEmpty = _checkIsCartEmpty(customer);

          if (cartItemDetailsList.isEmpty || isCartEmpty) {
            return const EmptyCartScreen();
          }

          final shopName = cartItemDetailsList.first.product.shop.displayName;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your bag', style: AppTextStyles.heading1)
                          .animateEntrance(),
                      const SizedBox(height: 6),
                      // Nearzy orders are single-shop, so naming the shop up
                      // front explains the constraint before checkout does.
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              size: 14, color: AppColors.sageDeep),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${cartItemDetailsList.length} item'
                              '${cartItemDetailsList.length == 1 ? '' : 's'} from $shopName',
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ).animateEntrance(index: 1),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
                  180,
                ),
                sliver: SliverList.separated(
                  itemCount: cartItemDetailsList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cartItemDetailsList[index];
                    return _CartRow(
                      item: item,
                      onOpen: () => context.pushScreen(
                        () => ProductDetailsScreen(product: item.product),
                      ),
                      onIncrease: () => context.read<CustomerDataBloc>().add(
                            CustomerDataIncreaseQuantityByOneEvent(
                              product: item.product,
                            ),
                          ),
                      onDecrease: item.quantity > 1
                          ? () => context.read<CustomerDataBloc>().add(
                                CustomerDataDecreaseQuantityByOneEvent(
                                  product: item.product,
                                ),
                              )
                          : null,
                      onRemove: () => context.read<CustomerDataBloc>().add(
                            CustomerDataRemoveProductFromCartEvent(
                              product: item.product,
                            ),
                          ),
                    ).animateEntrance(index: index);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: customer == null || isCartEmpty
          ? null
          : CartBottomBar(cartItemDetailsList: cartItemDetailsList),
    );
  }
}

/// One line item: image, name, unit price, stepper, remove.
class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onOpen,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItemDetails item;
  final VoidCallback onOpen;
  final VoidCallback onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppSpacing.shadowSubtle,
      ),
      child: Row(
        children: [
          PressableScale(
            onTap: onOpen,
            scale: 0.94,
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusMd,
              child: NearzyNetworkImage(
                url: item.product.images.isNotEmpty
                    ? item.product.images.first
                    : null,
                width: 76,
                height: 76,
                fallbackIcon: Icons.shopping_bag_outlined,
                semanticLabel: item.product.name,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.labelMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.product.price ~/ 100} each',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Stepper(
                      quantity: item.quantity,
                      onIncrease: onIncrease,
                      onDecrease: onDecrease,
                    ),
                    const Spacer(),
                    Text(
                      '₹${(item.product.price ~/ 100) * item.quantity}',
                      style: AppTextStyles.priceSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Remove from bag',
            onPressed: () {
              HapticFeedback.mediumImpact();
              onRemove();
            },
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Quantity stepper. The number cross-fades on change rather than snapping,
/// which makes rapid taps legible.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: onDecrease,
            tooltip: 'Decrease quantity',
          ),
          SizedBox(
            width: 30,
            child: AnimatedSwitcher(
              duration: Motion.duration(context, Motion.quick),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: onIncrease,
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: PressableScale(
        // Steppers get held down; a haptic per repeat is noise.
        haptics: false,
        onTap: onTap,
        scale: 0.86,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? AppColors.textTertiary : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn({required this.onLogin});

  final VoidCallback onLogin;

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
              child: const Icon(Icons.lock_outline_rounded,
                  size: 34, color: AppColors.sage),
            ).animateEntrance(),
            const SizedBox(height: 20),
            Text('Sign in to see your bag', style: AppTextStyles.heading2)
                .animateEntrance(index: 1),
            const SizedBox(height: 8),
            Text(
              'Your saved items are waiting. Sign in to pick up where you left off.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ).animateEntrance(index: 2),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: onLogin,
                child: const Text('Sign in'),
              ),
            ).animateEntrance(index: 3),
          ],
        ),
      ),
    );
  }
}

class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();

  @override
  Widget build(BuildContext context) =>
      ShimmerLoading.listRows(count: 3, height: 100);
}

class CartBottomBar extends StatelessWidget {
  const CartBottomBar({super.key, required this.cartItemDetailsList});

  final List<CartItemDetails> cartItemDetailsList;

  @override
  Widget build(BuildContext context) {
    final total = calculateTotalPrice(cartItemDetailsList);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppSpacing.shadowElevated,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        16,
        AppSpacing.gutter,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Subtotal', style: AppTextStyles.bodySmall),
              const Spacer(),
              // The running total tweens rather than jumping, so a quantity
              // change is visibly connected to the number that reflects it.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: total, end: total),
                duration: Motion.duration(context, Motion.base),
                curve: Motion.easeOut,
                builder: (context, value, _) => Text(
                  '₹${value.round()}',
                  style: AppTextStyles.priceMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Delivery', style: AppTextStyles.bodySmall),
              const Spacer(),
              Text('Calculated at checkout', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pushScreen(
                () => CheckoutScreen(cartItemDetailst: cartItemDetailsList),
              ),
              child: const Text('Proceed to checkout'),
            ),
          ),
        ],
      ),
    );
  }
}

double calculateTotalPrice(List<CartItemDetails> cartItemDetails) {
  double totalPrice = 0.0;
  for (var item in cartItemDetails) {
    totalPrice += (item.product.price ~/ 100) * item.quantity;
  }
  return totalPrice;
}
