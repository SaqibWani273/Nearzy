import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/product.dart';
import '../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/nearzy_page_route.dart';
import '../../../common/widgets/nearzy_product_card.dart';
import '../../../common/widgets/shimmer_loading.dart';
import '../dashboard/view_model/customer_data_bloc.dart';
import '../product/view/product_details_screen.dart';

/// Discounted products from shops in the customer's area, biggest saving
/// first — the "Special offers" destination in the drawer.
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  late Future<List<Product>> _offers;

  @override
  void initState() {
    super.initState();
    _offers = _load();
  }

  Future<List<Product>> _load() {
    final repository = context.read<CustomerDataRepository>();
    return ApiService.fetchDiscountedProducts(
      repository.currentSelectedLocation,
      radiusKm: repository.radiusKm,
    );
  }

  int _savingPercent(Product p) => p.price <= 0
      ? 0
      : (((p.price - p.disCountedPrice) / p.price) * 100).round();

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CustomerDataRepository>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Special offers')),
      body: RefreshIndicator.adaptive(
        color: AppColors.ink,
        backgroundColor: AppColors.card,
        onRefresh: () async => setState(() => _offers = _load()),
        child: BlocBuilder<CustomerDataBloc, CustomerDataState>(
          builder: (context, _) => FutureBuilder<List<Product>>(
            future: _offers,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  children: [
                    const SizedBox(height: 12),
                    ShimmerLoading.productGrid(count: 4),
                  ],
                );
              }

              final offers = snapshot.data ?? const <Product>[];
              if (offers.isEmpty) return const _NoOffers();

              final best = offers.first;

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
                        20,
                      ),
                      child: _HeadlineBanner(
                        percent: _savingPercent(best),
                        count: offers.length,
                        area: repository
                                .currentSelectedLocation?.shortAddress ??
                            'your area',
                      ).animateEntrance(),
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
                        childCount: offers.length,
                        (context, index) {
                          final product = offers[index];
                          return NearzyProductCard(
                            name: product.name,
                            imageUrl: product.images.isNotEmpty
                                ? product.images.first
                                : '',
                            priceInPaise: product.price,
                            discountedPriceInPaise: product.disCountedPrice,
                            rating: product.rating,
                            shopName: product.shop.displayName,
                            distanceLabel: product.shop.distanceLabel,
                            heroTag: 'offer-${product.id ?? index}',
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

class _HeadlineBanner extends StatelessWidget {
  const _HeadlineBanner({
    required this.percent,
    required this.count,
    required this.area,
  });

  final int percent;
  final int count;
  final String area;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UP TO',
                  style: AppTextStyles.overline.copyWith(color: AppColors.sage),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percent% off',
                  style:
                      AppTextStyles.display.copyWith(color: AppColors.lime),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count deal${count == 1 ? '' : 's'} from shops in $area',
                  style: AppTextStyles.caption.copyWith(color: AppColors.sage),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer_rounded,
                size: 26, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _NoOffers extends StatelessWidget {
  const _NoOffers();

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.local_offer_outlined,
                    size: 34, color: AppColors.sage),
              ).animateEntrance(),
              const SizedBox(height: 20),
              Text('No offers right now', style: AppTextStyles.heading3)
                  .animateEntrance(index: 1),
              const SizedBox(height: 6),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                child: Text(
                  'Shops near you have not put anything on discount yet. '
                  'Try widening your area.',
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
