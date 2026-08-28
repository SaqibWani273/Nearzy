import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/cart.dart';
import '../../../../data/models/customer.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../checkout/checkout_screen.dart';
import '../authentication/view/customer_login.dart';
import '../product/view/product_details_screen.dart';
import '/data/repositories/customer/customer_data_repository.dart';
import '/presentation/common/screens/error_screen.dart';
import '/presentation/common/widgets/shimmer_loading.dart';
import '/presentation/features/customer/cart/widgets/empty_cart_screen.dart';
import '/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';

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
    customer = context.read<CustomerDataRepository>().customer;
    cartItemDetailsList = context.read<CustomerDataRepository>().cartItemDetails;
    if (customer != null) {
      isCartEmpty = checkIsCartEmpty(customer);
      if (!isCartEmpty && cartItemDetailsList.isEmpty) {
        context.read<CustomerDataBloc>().add(
            CustomerDataFetchCartItemDetailsEvent(
                cartItems: customer!.cartItems!));
      }
    }
    super.initState();
  }

  bool checkIsCartEmpty(Customer? customer) =>
      customer == null ||
      customer.cartItems == null ||
      customer.cartItems!.isEmpty;

  Widget notLoggedInWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppSpacing.shadowMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text('Your Cart is Waiting', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Log in to view items previously added to your cart and checkout effortlessly.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CustomerLogin()),
                  );
                  customer = context.read<CustomerDataRepository>().customer;
                  if (customer != null) {
                    isCartEmpty = checkIsCartEmpty(customer);
                    if (!isCartEmpty) {
                      context.read<CustomerDataBloc>().add(
                          CustomerDataFetchCartItemDetailsEvent(
                              cartItems: customer!.cartItems!));
                    }
                  }
                  setState(() {});
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Login to Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<CustomerDataBloc, CustomerDataState>(
        builder: (context, state) {
          customer = context.read<CustomerDataRepository>().customer;
          if (customer == null) {
            return notLoggedInWidget();
          }
          if (state is CustomerDataFetchingCartItemDetailsState) {
            return ShimmerLoading.productGrid(count: 2);
          }
          if (state is CustomerDataCartErrorState) {
            return ErrorScreen(
              customException: state.error,
              onTryAgainPressed: () {
                context.read<CustomerDataBloc>().add(
                    CustomerDataFetchCartItemDetailsEvent(
                        cartItems: customer!.cartItems!));
              },
            );
          }

          cartItemDetailsList =
              context.read<CustomerDataRepository>().cartItemDetails;
          isCartEmpty = checkIsCartEmpty(customer);
          if (cartItemDetailsList.isEmpty || isCartEmpty) {
            return const EmptyCartScreen();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: cartItemDetailsList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cartItem = cartItemDetailsList[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppSpacing.borderRadiusMd,
                  boxShadow: AppSpacing.shadowSubtle,
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailsScreen(product: cartItem.product),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: AppSpacing.borderRadiusSm,
                        child: Image.network(
                          cartItem.product.images.isNotEmpty
                              ? cartItem.product.images.first
                              : '',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 72,
                            height: 72,
                            color: AppColors.inputFill,
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cartItem.product.name,
                            style: AppTextStyles.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${cartItem.product.price ~/ 100}',
                            style: AppTextStyles.priceSmall
                                .copyWith(color: AppColors.accent),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: () {
                                  if (cartItem.quantity > 1) {
                                    context.read<CustomerDataBloc>().add(
                                        CustomerDataDecreaseQuantityByOneEvent(
                                            product: cartItem.product));
                                  }
                                },
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${cartItem.quantity}',
                                  style: AppTextStyles.labelLarge,
                                ),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: () => context.read<CustomerDataBloc>().add(
                                    CustomerDataIncreaseQuantityByOneEvent(
                                        product: cartItem.product)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      onPressed: () {
                        context.read<CustomerDataBloc>().add(
                            CustomerDataRemoveProductFromCartEvent(
                                product: cartItem.product));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomSheet: customer == null || isCartEmpty
          ? null
          : CartBottomBar(cartItemDetailsList: cartItemDetailsList),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class CartBottomBar extends StatelessWidget {
  final List<CartItemDetails> cartItemDetailsList;

  const CartBottomBar({super.key, required this.cartItemDetailsList});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Amount', style: AppTextStyles.caption),
                Text(
                  '₹${calculateTotalPrice(cartItemDetailsList).toInt()}',
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                  return CheckoutScreen(cartItemDetailst: cartItemDetailsList);
                }));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Checkout',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
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
