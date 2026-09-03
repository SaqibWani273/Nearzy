import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../data/models/product.dart';
import '../../../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../../../theme/app_spacing.dart';
import '../../../../../common/animations/entrance.dart';
import '../../../../../common/animations/nearzy_page_route.dart';
import '../../../../../common/widgets/nearzy_product_card.dart';
import '../../../product/view/product_details_screen.dart';
import '../../view_model/customer_data_bloc.dart';

/// Horizontal rail of product cards.
///
/// Sized to the same 168×268 silhouette the grid skeleton uses, so a rail and
/// the feed below it read as one catalogue rather than two components that
/// happen to share a screen.
class ProductCarousel extends StatelessWidget {
  const ProductCarousel({
    super.key,
    required this.products,
    required this.heroPrefix,
    this.cardWidth = 168,
    this.height = 268,
  });

  final List<Product> products;

  /// Hero tags have to be unique within a screen, and the same product can
  /// appear in two rails — so each rail namespaces its own.
  final String heroPrefix;

  final double cardWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CustomerDataRepository>();

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.gridGap),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: cardWidth,
            child: NearzyProductCard(
              name: product.name,
              imageUrl: product.images.isNotEmpty ? product.images.first : '',
              priceInPaise: product.price,
              discountedPriceInPaise: product.disCountedPrice < product.price
                  ? product.disCountedPrice
                  : null,
              rating: product.rating,
              shopName: product.shop.displayName,
              distanceLabel: product.shop.distanceLabel,
              heroTag: '$heroPrefix-${product.id ?? index}',
              isFavourite: repository.isFavourite(product.id),
              onFavouriteToggle: () => context
                  .read<CustomerDataBloc>()
                  .add(CustomerDataToggleFavouriteEvent(product: product)),
              onTap: () => context.pushScreen(
                () => ProductDetailsScreen(product: product),
              ),
            ),
            // Horizontal so the entrance travels along the rail's own axis —
            // a vertical lift inside a sideways scroller reads as a glitch.
          ).animateEntrance(index: index, horizontal: true, offset: 24);
        },
      ),
    );
  }
}
