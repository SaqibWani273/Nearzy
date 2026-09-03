import 'package:flutter/material.dart';

import '../../../../../data/models/product.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/widgets/nearzy_product_card.dart';

/// Customer-facing search results.
///
/// Uses the shared [NearzyProductCard] rather than the shop's inventory row —
/// it borrowed that card while the operator screens were unstyled, which meant
/// customers saw a stock-management layout complete with SKU and stock count.
class SearchProductScreen extends StatelessWidget {
  const SearchProductScreen({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text('No products found', style: AppTextStyles.bodyMedium),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.gridGap,
        mainAxisSpacing: AppSpacing.gridGap,
        // Fixed extent rather than an aspect ratio, which breaks once a
        // product name wraps to a second line.
        mainAxisExtent: 274,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        final discount = product.discountInPercentage ?? 0;
        return NearzyProductCard(
          name: product.name,
          imageUrl: product.images.isEmpty ? '' : product.images.first,
          priceInPaise: product.price,
          discountedPriceInPaise: discount > 0
              ? (product.price * (1 - discount / 100)).round()
              : null,
          rating: product.rating,
          shopName: product.shop.name,
          heroTag: product.id == null ? null : 'product-${product.id}',
        );
      },
    );
  }
}
