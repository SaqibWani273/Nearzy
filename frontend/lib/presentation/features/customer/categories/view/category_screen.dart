import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../data/models/category/product_category/product_category.dart';
import '../../../../../data/models/product.dart';
import '../../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../../services/api_service.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/animations/entrance.dart';
import '../../../../common/animations/nearzy_page_route.dart';
import '../../../../common/widgets/nearzy_product_card.dart';
import '../../../../common/widgets/shimmer_loading.dart';
import '../../dashboard/view_model/customer_data_bloc.dart';
import '../../product/view/product_details_screen.dart';

/// Products within one category, scoped to the customer's browsing area.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final ProductCategory category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    _products = _load();
  }

  /// Asks the server rather than filtering the already-paged feed: the feed
  /// holds only the pages the user has scrolled through, so filtering it
  /// showed a near-empty category on a fresh launch.
  Future<List<Product>> _load() {
    final repository = context.read<CustomerDataRepository>();
    return ApiService.fetchProductsByCategoryId(
      widget.category.id,
      location: repository.currentSelectedLocation,
      radiusKm: repository.radiusKm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CustomerDataRepository>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text(widget.category.name)),
      body: RefreshIndicator.adaptive(
        color: AppColors.ink,
        backgroundColor: AppColors.card,
        onRefresh: () async => setState(() => _products = _load()),
        // Rebuilds the hearts: the repository holding them is a plain object,
        // so only a bloc emission can drive a repaint.
        child: BlocBuilder<CustomerDataBloc, CustomerDataState>(
          builder: (context, _) => FutureBuilder<List<Product>>(
            future: _products,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  children: [
                    const SizedBox(height: 12),
                    ShimmerLoading.productGrid(count: 4),
                  ],
                );
              }

              final products = snapshot.data ?? const <Product>[];
              if (products.isEmpty) return const _EmptyCategory();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        4,
                        AppSpacing.gutter,
                        16,
                      ),
                      child: Text(
                        '${products.length} item'
                        '${products.length == 1 ? '' : 's'} near '
                        '${repository.currentSelectedLocation?.shortAddress ?? 'you'}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                            heroTag: 'product-${product.id ?? index}',
                            isFavourite: repository.isFavourite(product.id),
                            onFavouriteToggle: () =>
                                context.read<CustomerDataBloc>().add(
                                  CustomerDataToggleFavouriteEvent(
                                    product: product,
                                  ),
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
          ),
        ),
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory();

  @override
  Widget build(BuildContext context) {
    // A ListView so pull-to-refresh still works with nothing to show.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 34,
                  color: AppColors.sage,
                ),
              ).animateEntrance(),
              const SizedBox(height: 20),
              Text(
                'Nothing in this category yet',
                style: AppTextStyles.heading3,
              ).animateEntrance(index: 1),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                child: Text(
                  'No shops nearby are listing these right now. Try a wider area.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ).animateEntrance(index: 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
