import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../../constants/rest_api_const.dart';
import '../../../../../data/models/product.dart';
import '../../../../../data/models/shop_model/shop_model1.dart';
import '../../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_motion.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/animations/entrance.dart';
import '../../../../common/animations/nearzy_page_route.dart';
import '../../../../common/animations/pressable_scale.dart';
import '../../../../common/screens/error_screen.dart';
import '../../../../common/widgets/nearzy_product_card.dart';
import '../../../../common/widgets/nearzy_search_bar.dart';
import '../../../../common/widgets/section_header.dart';
import '../../../../common/widgets/shimmer_loading.dart';
import '../../location/location_picker_screen.dart';
import '../../product/view/product_details_screen.dart';
import '../view_model/customer_data_bloc.dart';

/// The customer's home feed: search, a location banner, and a paginated
/// product grid scoped to wherever they're shopping.
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  late final PagingController<int, Product> _pagingController;
  Timer? _searchDebounce;

  /// Recent searches only appear while the field has focus.
  bool _searchFocused = false;

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
      fetchPage: repository.fetchProducts,
    );
    repository.globalPagingController = _pagingController;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _pagingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  CustomerDataRepository get _repo => context.read<CustomerDataRepository>();

  /// Debounced so a five-letter query is one request, not five.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final term = value.trim();

    if (term.isEmpty) {
      context.read<CustomerDataBloc>().add(CustomerDataClearSearchEvent());
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context
          .read<CustomerDataBloc>()
          .add(CustomerDataSearchProductEvent(keyword: term));
    });
  }

  Future<void> _changeLocation() async {
    final picked = await context.pushModal<LocationInfo>(
      () => LocationPickerScreen(initial: _repo.currentSelectedLocation),
    );
    if (picked == null || !mounted) return;
    context
        .read<CustomerDataBloc>()
        .add(SetCustomerLocationEvent(location: picked));
  }

  void _openProduct(Product product) {
    context.pushScreen(() => ProductDetailsScreen(product: product));
  }

  Widget _card(Product product, int index) {
    return NearzyProductCard(
      name: product.name,
      imageUrl: product.images.isNotEmpty ? product.images.first : '',
      priceInPaise: product.price,
      discountedPriceInPaise: product.disCountedPrice < product.price
          ? product.disCountedPrice
          : null,
      rating: product.rating,
      shopName: product.shop.displayName,
      distanceLabel: product.shop.distanceLabel,
      heroTag: 'product-${product.id ?? index}',
      isFavourite: _repo.isFavourite(product.id),
      onFavouriteToggle: () => context
          .read<CustomerDataBloc>()
          .add(CustomerDataToggleFavouriteEvent(product: product)),
      onTap: () => _openProduct(product),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<CustomerDataBloc, CustomerDataState>(
      builder: (context, state) {
        if (state is CustomerDataErrorState) {
          return _FeedError(
            message: state.error,
            onRetry: () =>
                context.read<CustomerDataBloc>().add(LoadCustomerDataEvent()),
          );
        }

        if (state is CustomerDataLocationErrorState) {
          return ErrorScreen(
            customException: state.error,
            onTryAgainPressed: () =>
                context.read<CustomerDataBloc>().add(LoadCustomerDataEvent()),
          );
        }

        if (state is! CustomerDataLoadedState) {
          return const _FeedSkeleton();
        }

        return RefreshIndicator.adaptive(
          color: AppColors.ink,
          backgroundColor: AppColors.card,
          onRefresh: () async => context
              .read<CustomerDataBloc>()
              .add(CustomerDataLoadProductsEvent()),
          child: PagingListener<int, Product>(
            controller: _pagingController,
            builder: (context, pagingState, fetchNextPage) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: NearzySearchBar(
                      controller: _searchController,
                      hintText: 'Search products, brands & shops',
                      onChanged: _onSearchChanged,
                      onFocusChange: (focused) =>
                          setState(() => _searchFocused = focused),
                      onClear: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ).animateEntrance(),
                  ),

                  // Recent searches, offered while the field is focused and
                  // empty — the one moment they are useful rather than noise.
                  if (_searchFocused &&
                      _searchController.text.isEmpty &&
                      _repo.recentSearches.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _RecentSearches(
                        terms: _repo.recentSearches,
                        onSelect: (term) {
                          _searchController.text = term;
                          _onSearchChanged(term);
                        },
                        onClear: () async {
                          await _repo.clearRecentSearches();
                          if (mounted) setState(() {});
                        },
                      ),
                    ),

                  // The location banner is hidden while searching — search
                  // results are global, so showing a local banner over them
                  // would be a lie.
                  if (state.searchProducts == null)
                    SliverToBoxAdapter(
                      child: _LocationBanner(
                        location: _repo.currentSelectedLocation,
                        busy: state.isChangingLocation == true,
                        onTap: _changeLocation,
                      ).animateEntrance(index: 1),
                    ),

                  if (state.loadingProducts == true)
                    SliverToBoxAdapter(
                      child: ShimmerLoading.productGrid(count: 4),
                    )
                  else if (state.searchProducts != null) ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Search results',
                        subtitle: state.searchProducts!.isEmpty
                            ? 'Nothing matched that'
                            : '${state.searchProducts!.length} found',
                      ),
                    ),
                    if (state.searchProducts!.isEmpty)
                      SliverToBoxAdapter(
                        child: _EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matches',
                          message:
                              'Try a different word, or browse the feed below.',
                        ),
                      )
                    else
                      _grid(
                        itemCount: state.searchProducts!.length,
                        builder: (context, index) =>
                            _card(state.searchProducts![index], index),
                      ),
                  ] else ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Picked for you',
                        subtitle: 'Fresh from shops around you',
                      ).animateEntrance(index: 2),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                      ),
                      sliver: PagedSliverGrid<int, Product>(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 268,
                          crossAxisSpacing: AppSpacing.gridGap,
                          mainAxisSpacing: AppSpacing.gridGap,
                        ),
                        state: pagingState,
                        fetchNextPage: fetchNextPage,
                        builderDelegate: PagedChildBuilderDelegate<Product>(
                          firstPageProgressIndicatorBuilder: (_) =>
                              ShimmerLoading.productGrid(count: 4),
                          newPageProgressIndicatorBuilder: (_) =>
                              const _PageSpinner(),
                          noItemsFoundIndicatorBuilder: (_) => _EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'Nothing here yet',
                            message:
                                'No products from shops in this area. Try a different location.',
                            actionLabel: 'Change location',
                            onAction: _changeLocation,
                          ),
                          itemBuilder: (context, item, index) =>
                              _card(item, index).animateEntrance(index: index),
                        ),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.bottomNavInset),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  SliverPadding _grid({
    required int itemCount,
    required Widget Function(BuildContext, int) builder,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 268,
          crossAxisSpacing: AppSpacing.gridGap,
          mainAxisSpacing: AppSpacing.gridGap,
        ),
        delegate: SliverChildBuilderDelegate(
          childCount: itemCount,
          (context, index) =>
              builder(context, index).animateEntrance(index: index),
        ),
      ),
    );
  }
}

/// Ink banner naming the area the feed is scoped to.
class _LocationBanner extends StatelessWidget {
  const _LocationBanner({
    required this.location,
    required this.busy,
    required this.onTap,
  });

  final LocationInfo? location;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        4,
        AppSpacing.gutter,
        4,
      ),
      child: PressableScale(
        onTap: onTap,
        scale: 0.985,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            gradient: AppColors.inkGradient,
            borderRadius: AppSpacing.borderRadiusXl,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.place_rounded,
                    size: 19, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHOPPING IN',
                      style: AppTextStyles.overline
                          .copyWith(color: AppColors.sage),
                    ),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: Motion.duration(context, Motion.base),
                      child: Text(
                        busy
                            ? 'Updating…'
                            : (location?.shortAddress ?? 'Everywhere'),
                        key: ValueKey(busy ? 'busy' : location?.shortAddress),
                        style: AppTextStyles.heading4
                            .copyWith(color: AppColors.paper),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.inkMuted,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  'Change',
                  style:
                      AppTextStyles.labelSmall.copyWith(color: AppColors.lime),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageSpinner extends StatelessWidget {
  const _PageSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: ShimmerLoading.line(height: 52),
          ),
          const SizedBox(height: 14),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: ShimmerLoading.line(height: 72),
          ),
          const SizedBox(height: 20),
          ShimmerLoading.productGrid(count: 4),
        ],
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line, width: 1.5),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 34, color: AppColors.sage),
            ).animateEntrance(),
            const SizedBox(height: 20),
            Text('Could not load the feed', style: AppTextStyles.heading3)
                .animateEntrance(index: 1),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ).animateEntrance(index: 2),
            const SizedBox(height: 22),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again'))
                .animateEntrance(index: 3),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: 40,
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Icon(icon, size: 34, color: AppColors.sage),
          ).animateEntrance(),
          const SizedBox(height: 18),
          Text(title, style: AppTextStyles.heading3).animateEntrance(index: 1),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ).animateEntrance(index: 2),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!))
                .animateEntrance(index: 3),
          ],
        ],
      ),
    );
  }
}


/// Chips for the customer's last few searches.
class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.terms,
    required this.onSelect,
    required this.onClear,
  });

  final List<String> terms;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('RECENT', style: AppTextStyles.overline),
              const Spacer(),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Clear',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textTertiary)),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: AppSpacing.gutter),
              itemCount: terms.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => PressableScale(
                onTap: () => onSelect(terms[index]),
                scale: 0.94,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppSpacing.borderRadiusFull,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(terms[index], style: AppTextStyles.labelSmall),
                    ],
                  ),
                ),
              ).animateEntrance(index: index, offset: 8),
            ),
          ),
        ],
      ),
    );
  }
}
