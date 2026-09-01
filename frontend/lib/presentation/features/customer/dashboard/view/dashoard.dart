import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/data/models/shop_model/shop_model1.dart';
import 'package:mca_project/presentation/common/screens/error_screen.dart';
import '../../../../../data/models/product.dart';
import '../../../../common/widgets/nearzy_product_card.dart';
import '../../../../common/widgets/nearzy_search_bar.dart';
import '../../../../common/widgets/section_header.dart';
import '../../../../common/widgets/shimmer_loading.dart';
import '/presentation/common/widgets/show_cupertino_alert_dialog.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '/presentation/features/customer/product/view/product_details_screen.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../constants/rest_api_const.dart';
import '/data/repositories/customer/customer_data_repository.dart';
import '/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with AutomaticKeepAliveClientMixin {
  TextEditingController locationController = TextEditingController();
  late final PagingController<int, Product> _pagingController;

  LocationInfo? locationInfo;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final repository = context.read<CustomerDataRepository>();
    context.read<CustomerDataBloc>().add(LoadCustomerDataEvent());
    repository.products = [];
    _pagingController = PagingController<int, Product>(
      getNextPageKey: (state) {
        final pages = state.pages;
        // Nothing fetched yet — start at the first page.
        if (pages == null || pages.isEmpty) return 0;
        // A short page means the server has no more products.
        if (pages.last.length < ApiConst.pageSize) return null;
        return (state.keys?.last ?? 0) + 1;
      },
      fetchPage: (pageKey) => repository.fetchProducts(pageKey),
    );
    repository.globalPagingController = _pagingController;
  }

  @override
  void dispose() {
    _pagingController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<CustomerDataBloc, CustomerDataState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is CustomerDataErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(state.error, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.read<CustomerDataBloc>().add(
                      LoadCustomerDataEvent(),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (state is CustomerDataLoadingState) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  ShimmerLoading.line(width: double.infinity, height: 48),
                  const SizedBox(height: 16),
                  ShimmerLoading.productGrid(count: 6),
                ],
              ),
            );
          }

          if (state is CustomerDataLocationErrorState) {
            return ErrorScreen(
              customException: state.error,
              onTryAgainPressed: () {
                context.read<CustomerDataBloc>().add(LoadCustomerDataEvent());
              },
            );
          }

          if (state is CustomerDataLoadedState) {
            return PagingListener<int, Product>(
              controller: _pagingController,
              builder: (context, pagingState, fetchNextPage) => CustomScrollView(
                slivers: [
                  // ── Search bar ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: NearzySearchBar(
                      hintText: 'Search products, brands & more',
                      onChanged: (value) {
                        context.read<CustomerDataBloc>().add(
                          CustomerDataSearchProductEvent(keyword: value),
                        );
                      },
                    ),
                  ),

                  // ── Location change bar ───────────────────────────────
                  if (state.isChangingLocation == null)
                    SliverToBoxAdapter(
                      child: _LocationBar(
                        controller: locationController,
                        context: context,
                      ),
                    ),

                  if (state.isChangingLocation == true)
                    SliverToBoxAdapter(
                      child: ShimmerLoading.line(
                        width: double.infinity,
                        height: 52,
                      ),
                    ),

                  // ── Loading products indicator ────────────────────────
                  if (state.loadingProducts == true)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: deviceHeight * 0.1),
                        child: ShimmerLoading.productGrid(count: 4),
                      ),
                    ),

                  // ── Search results ────────────────────────────────────
                  if (state.loadingProducts == null &&
                      state.searchProducts != null) ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Search Results',
                        subtitle:
                            '${state.searchProducts!.length} products found',
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = state.searchProducts![index];
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
                            shopName: product.shop.user.username,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailsScreen(product: product),
                              ),
                            ),
                          );
                        }, childCount: state.searchProducts!.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.65,
                            ),
                      ),
                    ),
                  ],

                  // ── Main product grid ─────────────────────────────────
                  if (state.loadingProducts == null &&
                      state.searchProducts == null) ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Products For You',
                        subtitle: 'Handpicked from local shops',
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      sliver: PagedSliverGrid<int, Product>(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: deviceHeight * 0.3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        state: pagingState,
                        fetchNextPage: fetchNextPage,
                        builderDelegate: PagedChildBuilderDelegate<Product>(
                          firstPageProgressIndicatorBuilder: (_) =>
                              ShimmerLoading.productGrid(count: 4),
                          newPageProgressIndicatorBuilder: (_) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          noItemsFoundIndicatorBuilder: (_) => _EmptyState(),
                          itemBuilder: (context, item, index) {
                            return NearzyProductCard(
                              name: item.name,
                              imageUrl: item.images.isNotEmpty
                                  ? item.images.first
                                  : '',
                              priceInPaise: item.price,
                              discountedPriceInPaise:
                                  item.disCountedPrice < item.price
                                  ? item.disCountedPrice
                                  : null,
                              rating: item.rating,
                              shopName: item.shop.user.username,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsScreen(product: item),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          }

          return ShimmerLoading.productGrid(count: 4);
        },
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  final TextEditingController controller;
  final BuildContext context;

  const _LocationBar({required this.controller, required this.context});

  @override
  Widget build(BuildContext context) {
    final location = context
        .read<CustomerDataRepository>()
        .currentSelectedLocation;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySurface, AppColors.card],
        ),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location == null ? 'Global' : location.shortAddress,
                  style: AppTextStyles.labelLarge,
                ),
                Text(
                  'Showing products from nearby shops',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              showCupertinoAlertDialog(
                context: context,
                controller: controller,
                title: 'Change Location',
                content: 'Enter a valid location name',
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Change',
              style: AppTextStyles.link.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Text('No Products Found', style: AppTextStyles.heading4),
          const SizedBox(height: 8),
          Text(
            'Try changing your location or search terms',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Product card used in search results — kept for backwards compat.
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: AppSpacing.borderRadiusSm,
        child: Image.network(
          product.images.isNotEmpty ? product.images.first : '',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 56,
            height: 56,
            color: AppColors.inputFill,
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
      title: Text(product.name, style: AppTextStyles.labelLarge),
      subtitle: Text(
        '₹${product.disCountedPrice < product.price ? product.disCountedPrice : product.price}',
        style: AppTextStyles.priceSmall.copyWith(color: AppColors.accent),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.textTertiary,
      ),
    );
  }
}
