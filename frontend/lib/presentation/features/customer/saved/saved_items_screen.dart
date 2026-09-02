import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/cart.dart';
import '../../../../data/models/product.dart';
import '../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../services/customer_profile_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/nearzy_page_route.dart';
import '../../../common/widgets/nearzy_product_card.dart';
import '../../../common/widgets/shimmer_loading.dart';
import '../dashboard/view_model/customer_data_bloc.dart';
import '../product/view/product_details_screen.dart';

/// Products the customer has hearted.
///
/// Favourites are stored on the device as bare product ids, so this screen
/// rehydrates them through the existing get-products-by-ids endpoint rather
/// than needing a server-side wishlist.
class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  late Future<List<Product>> _saved;

  @override
  void initState() {
    super.initState();
    _saved = _load();
  }

  Future<List<Product>> _load() async {
    final ids = context.read<CustomerDataRepository>().favouriteProductIds;
    if (ids.isEmpty) return const [];

    final details = await CustomerProfileService.fetchProductsFromIds(
      ids.map((id) => CartItem(productId: id, quantity: 1)).toList(),
    );
    return details.map((d) => d.product).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Saved items')),
      // The repository is a plain object, not a Listenable, so watching it
      // would never rebuild. The bloc emits a new state on every toggle.
      body: BlocBuilder<CustomerDataBloc, CustomerDataState>(
        builder: (context, _) => _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final repository = context.read<CustomerDataRepository>();

    return FutureBuilder<List<Product>>(
      future: _saved,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            children: [
              const SizedBox(height: 12),
              ShimmerLoading.productGrid(count: 4),
            ],
          );
        }

        // Unhearting on this screen should remove the card immediately,
        // without a refetch — filter the loaded list against live state.
        final products = (snapshot.data ?? const <Product>[])
            .where((p) => repository.isFavourite(p.id))
            .toList();

        if (products.isEmpty) return const _NothingSaved();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                12,
                AppSpacing.gutter,
                0,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 268,
                  crossAxisSpacing: AppSpacing.gridGap,
                  mainAxisSpacing: AppSpacing.gridGap,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: products.length,
                  (context, index) {
                    final product = products[index];
                    return NearzyProductCard(
                      name: product.name,
                      imageUrl: product.images.isNotEmpty
                          ? product.images.first
                          : '',
                      priceInPaise: product.price,
                      discountedPriceInPaise:
                          product.disCountedPrice < product.price
                          ? product.disCountedPrice
                          : null,
                      rating: product.rating,
                      shopName: product.shop.displayName,
                      distanceLabel: product.shop.distanceLabel,
                      heroTag: 'saved-${product.id ?? index}',
                      isFavourite: true,
                      onFavouriteToggle: () =>
                          context.read<CustomerDataBloc>().add(
                            CustomerDataToggleFavouriteEvent(product: product),
                          ),
                      onTap: () => context.pushScreen(
                        () => ProductDetailsScreen(product: product),
                      ),
                    ).animateEntrance(index: index);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }
}

class _NothingSaved extends StatelessWidget {
  const _NothingSaved();

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
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 34,
                color: AppColors.sage,
              ),
            ).animateEntrance(),
            const SizedBox(height: 20),
            Text(
              'Nothing saved yet',
              style: AppTextStyles.heading3,
            ).animateEntrance(index: 1),
            const SizedBox(height: 6),
            Text(
              'Tap the heart on anything you want to come back to.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ).animateEntrance(index: 2),
          ],
        ),
      ),
    );
  }
}
