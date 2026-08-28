import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/data/models/shop_model/shop_model1.dart';
import 'package:mca_project/presentation/common/widgets/shimmer_loading.dart';
import '/data/repositories/customer/customer_data_repository.dart';
import '/presentation/features/customer/cart/cart_screen.dart';
import '/utils/utils.dart';
import '../../../../../data/models/customer.dart';
import '../../../../../data/models/product.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../appbar_widget.dart';
import '../../authentication/view/customer_login.dart';
import '../../dashboard/view/widgets/large_sliding_images_widget.dart';
import '../../dashboard/view_model/customer_data_bloc.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    Customer? customer = context.read<CustomerDataRepository>().customer;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          product.name,
          style: AppTextStyles.heading3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          CartIcon(customer: customer),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<CustomerDataBloc, CustomerDataState>(
        listener: (context, state) {
          if (state is CustomerDataLoadedState && state.canAddToCart == false) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Cart Shop Mismatch',
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.warning)),
                content: Text(
                  'All items in your cart must belong to the same local shop. Would you like to clear the cart and add this item?',
                  style: AppTextStyles.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          }
          if (state is CustomerDataLoadedState && state.canAddToCart == true) {
            Utils.showScaffoldMessage(
              message: "Added to Cart!",
              context: context,
              actionWidget: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                child: const Text("View Cart",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Slider ─────────────────────────────────────────
                Hero(
                  tag: 'product_${product.name}_${product.images.isNotEmpty ? product.images.first : ""}',
                  child: Container(
                    color: AppColors.card,
                    child: ImagesWidget(
                      slidingImages: product.images,
                      indicatorColor: AppColors.primary,
                      indicatorWidth: 8.0,
                    ),
                  ),
                ),

                Container(
                  color: AppColors.card,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stock Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.available
                              ? AppColors.successSurface
                              : AppColors.errorSurface,
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Text(
                          product.available ? "IN STOCK" : "OUT OF STOCK",
                          style: AppTextStyles.badge.copyWith(
                            color: product.available
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name & Brand
                      Text(product.name, style: AppTextStyles.heading2),
                      if (product.brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Brand: ${product.brand}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Price & Discount
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "₹${product.disCountedPrice ~/ 100}",
                            style: AppTextStyles.heading1
                                .copyWith(color: AppColors.primary),
                          ),
                          if (product.disCountedPrice < product.price) ...[
                            const SizedBox(width: 10),
                            Text(
                              "₹${product.price ~/ 100}",
                              style: AppTextStyles.priceStrikethrough
                                  .copyWith(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: AppSpacing.borderRadiusSm,
                              ),
                              child: Text(
                                '${(((product.price - product.disCountedPrice) / product.price) * 100).round()}% OFF',
                                style: AppTextStyles.badge,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Container(
                  color: AppColors.card,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Description", style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      Text(
                        product.completeDescription.isNotEmpty
                            ? product.completeDescription
                            : product.shortDescription,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Shop Details
                Container(
                  color: AppColors.card,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Sold by Local Shop",
                          style: AppTextStyles.heading3),
                      const SizedBox(height: 16),
                      buildShopDetails(product.shop),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (customer == null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomerLogin()),
                      );
                    } else {
                      if (!product.available) {
                        Utils.showScaffoldMessage(
                            message: "Product is currently out of stock",
                            context: context);
                        return;
                      }
                      context.read<CustomerDataBloc>().add(
                          CustomerDataAddProductToCartEvent(
                              product: product));
                    }
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text("Add to Cart"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: !product.available
                      ? null
                      : () async {
                          if (customer == null) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CustomerLogin()),
                            );
                          } else {
                            context.read<CustomerDataBloc>().add(
                                CustomerDataAddProductToCartEvent(
                                    product: product));
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CartScreen()),
                            );
                          }
                        },
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text("Buy Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildShopDetails(ShopModel1 shop) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.inputFill,
      borderRadius: AppSpacing.borderRadiusMd,
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(shop.ownerPicUrl),
              backgroundColor: AppColors.primarySurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.user.username, style: AppTextStyles.labelLarge),
                  Text('Owner: ${shop.ownerName}',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
        if (shop.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(shop.description,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                shop.address,
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
