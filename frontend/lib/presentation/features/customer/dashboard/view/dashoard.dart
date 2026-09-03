import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../../constants/rest_api_const.dart';
import '../../../../../data/models/category/product_category/product_category.dart';
import '../../../../../data/models/order.dart';
import '../../../../../data/models/product.dart';
import '../../../../../data/models/shop_model/shop_model1.dart';
import '../../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../../services/api_service.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/animations/cross_fade.dart';
import '../../../../common/animations/entrance.dart';
import '../../../../common/animations/nearzy_page_route.dart';
import '../../../../common/animations/pressable_scale.dart';
import '../../../../common/screens/error_screen.dart';
import '../../../../common/widgets/nearzy_product_card.dart';
import '../../../../common/widgets/nearzy_search_bar.dart';
import '../../../../common/widgets/section_header.dart';
import '../../../../common/widgets/shimmer_loading.dart';
import '../../categories/view/category_screen.dart';
import '../../customer_home_page.dart';
import '../../location/location_picker_screen.dart';
import '../../offers/offers_screen.dart';
import '../../product/view/product_details_screen.dart';
import '../../saved/saved_items_screen.dart';
import '../view_model/customer_data_bloc.dart';
import 'widgets/active_order_strip.dart';
import 'widgets/budget_picks_section.dart';
import 'widgets/category_rail.dart';
import 'widgets/dashboard_hero.dart';
import 'widgets/nearby_shops_rail.dart';
import 'widgets/product_carousel.dart';

/// The customer's home feed.
///
/// Reading order is deliberate: who and where you are, then anything already
/// in flight, then ways to narrow the catalogue, then curated rails, and
/// only at the bottom the endless grid. Someone waiting on a parcel should
/// never have to scroll past a carousel to find it.
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

  // ── Curated rails ─────────────────────────────────────────────────────
  // Every one of these resolves to a value, never an error: each API here
  // swallows its own failures and answers with an empty list. A dead rail
  // hides itself; it must never take the feed down with it.

  late Future<List<Product>> _deals;
  late Future<List<ShopModel1>> _nearbyShops;
  late Future<Order?> _activeOrder;

  /// The area the rails were loaded for. Compared against [_areaKey] so a
  /// location or radius change refetches them, and nothing else does.
  String _railsKey = '';

  /// Counters shown in the hero, filled in as the rails land.
  int? _shopCount;
  int? _dealCount;

  // ── Feed filter ───────────────────────────────────────────────────────

  /// The category the feed is narrowed to, or null for the default feed.
  ProductCategory? _category;

  /// Null while a category is still loading.
  List<Product>? _categoryResults;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final repository = context.read<CustomerDataRepository>();
    final bloc = context.read<CustomerDataBloc>();

    bloc.add(LoadCustomerDataEvent());
    // The category rail needs these; the Browse tab may already have them.
    if (repository.categories == null) {
      bloc.add(CustomerDataFetchCategoriesEvent());
    }
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

    _loadRails();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _pagingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  CustomerDataRepository get _repo => context.read<CustomerDataRepository>();

  /// Identifies the area being browsed, radius included — everything on this
  /// screen except the search results is scoped to it.
  String _areaKey() {
    final location = _repo.currentSelectedLocation;
    final radius = _repo.radiusKm;
    return location == null
        ? 'everywhere:$radius'
        : '${location.latitude},${location.longtitude}:$radius';
  }

  /// (Re)starts every rail's fetch. Call inside `setState`.
  void _loadRails({bool force = false}) {
    final repository = _repo;
    _railsKey = _areaKey();

    _deals = ApiService.fetchDiscountedProducts(
      repository.currentSelectedLocation,
      radiusKm: repository.radiusKm,
      limit: 12,
    );
    _nearbyShops = _loadShops(force: force);
    _activeOrder = _loadActiveOrder();

    _shopCount = null;
    _dealCount = null;
    _trackCount(_deals, (count) => _dealCount = count);
    _trackCount(_nearbyShops, (count) => _shopCount = count);
  }

  /// Mirrors a rail's length into the hero once it resolves. A rail that
  /// somehow fails just leaves its counter blank.
  void _trackCount<T>(Future<List<T>> future, void Function(int) apply) {
    future.then(
      (items) {
        if (mounted) setState(() => apply(items.length));
      },
      onError: (_, _) {},
    );
  }

  /// Nearby shops are shared with the Explore tab through the repository, so
  /// an unforced load reuses whatever the bloc last fetched rather than
  /// asking the server the same question twice.
  Future<List<ShopModel1>> _loadShops({required bool force}) {
    final cached = _repo.shops;
    if (!force && cached != null && cached.isNotEmpty) {
      return Future.value(cached);
    }
    return _repo.fetchNearbyShops();
  }

  /// The most recent order that is neither delivered nor cancelled. Null
  /// when there is none, when nobody is signed in, or when the request
  /// fails — the strip is a bonus, never a blocker.
  Future<Order?> _loadActiveOrder() async {
    if (_repo.customer == null) return null;
    try {
      final orders = await ApiService.fetchCustomerOrders(limit: 5);
      for (final order in orders) {
        if (!order.status.isTerminal) return order;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Search ────────────────────────────────────────────────────────────

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

  // ── Category filter ───────────────────────────────────────────────────

  void _selectCategory(ProductCategory? category) {
    setState(() {
      _category = category;
      _categoryResults = null;
    });
    if (category != null) _fetchCategoryProducts(category);
  }

  Future<void> _fetchCategoryProducts(ProductCategory category) async {
    final repository = _repo;
    final products = await ApiService.fetchProductsByCategoryId(
      category.id,
      location: repository.currentSelectedLocation,
      radiusKm: repository.radiusKm,
      limit: 40,
    );
    // Drop a response the customer has already navigated away from.
    if (!mounted || _category?.id != category.id) return;
    setState(() => _categoryResults = products);
  }

  // ── Navigation ────────────────────────────────────────────────────────

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

  void _goToExplore() =>
      HomeTabScope.maybeOf(context)?.goToTab(HomeTabScope.explore);

  Future<void> _refresh() async {
    context.read<CustomerDataBloc>().add(CustomerDataLoadProductsEvent());
    setState(() => _loadRails(force: true));
    final category = _category;
    if (category != null) _fetchCategoryProducts(category);
    try {
      // Keeps the spinner up until the rails have actually landed.
      await Future.wait<void>([_deals, _nearbyShops, _activeOrder]);
    } catch (_) {
      // Rails render their own empty states; a failure just ends the spin.
    }
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

    return BlocConsumer<CustomerDataBloc, CustomerDataState>(
      listener: (context, state) {
        // Refetch the rails once a location or radius change has settled —
        // by then the bloc has already refreshed the shared shop list, so
        // the unforced reload costs nothing.
        if (state is CustomerDataLoadedState &&
            state.isChangingLocation != true &&
            _railsKey != _areaKey()) {
          setState(_loadRails);
        }
      },
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

        final repository = _repo;
        // Search results are global; every discovery section below is scoped
        // to an area, so showing them over a search would be a lie.
        final searching =
            state.searchProducts != null || state.loadingProducts == true;
        final categories = repository.categories ?? const <ProductCategory>[];
        final filtered = _category != null;
        final showRails = !searching && !filtered;

        return RefreshIndicator.adaptive(
          color: AppColors.ink,
          backgroundColor: AppColors.card,
          onRefresh: _refresh,
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
                      repository.recentSearches.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _RecentSearches(
                        terms: repository.recentSearches,
                        onSelect: (term) {
                          _searchController.text = term;
                          _onSearchChanged(term);
                        },
                        onClear: () async {
                          await repository.clearRecentSearches();
                          if (mounted) setState(() {});
                        },
                      ),
                    ),

                  if (!searching)
                    SliverToBoxAdapter(
                      child: DashboardHero(
                        customerName: repository.customer?.user.username,
                        location: repository.currentSelectedLocation,
                        radiusKm: repository.radiusKm,
                        busy: state.isChangingLocation == true,
                        onChangeLocation: _changeLocation,
                        shopCount: _shopCount,
                        dealCount: _dealCount,
                        savedCount: repository.favouriteProductIds.length,
                        onShops: _goToExplore,
                        onDeals: () =>
                            context.pushScreen(() => const OffersScreen()),
                        onSaved: () =>
                            context.pushScreen(() => const SavedItemsScreen()),
                      ).animateEntrance(index: 1),
                    ),

                  // An undelivered order outranks discovery: someone who is
                  // waiting on a parcel opened the app to check on it.
                  if (!searching)
                    SliverToBoxAdapter(
                      child: FutureBuilder<Order?>(
                        future: _activeOrder,
                        builder: (context, snapshot) {
                          final order = snapshot.data;
                          if (order == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ActiveOrderStrip(order: order)
                                .animateEntrance(),
                          );
                        },
                      ),
                    ),

                  if (!searching && categories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: CategoryRail(
                          categories: categories,
                          selected: _category,
                          onSelect: _selectCategory,
                        ).animateEntrance(index: 2),
                      ),
                    ),

                  if (showRails)
                    SliverToBoxAdapter(
                      child: _RailSection<Product>(
                        future: _deals,
                        title: 'Deals near you',
                        subtitle: _dealsSubtitle,
                        skeleton: ShimmerLoading.productRow(count: 3),
                        onSeeAll: () =>
                            context.pushScreen(() => const OffersScreen()),
                        builder: (deals) => ProductCarousel(
                          products: deals,
                          heroPrefix: 'deal',
                        ),
                      ),
                    ),

                  if (showRails)
                    SliverToBoxAdapter(
                      child: _RailSection<ShopModel1>(
                        future: _nearbyShops,
                        title: 'Shops around you',
                        subtitle: (shops) =>
                            '${shops.length} open to browse · nearest first',
                        skeleton: ShimmerLoading.productRow(count: 3),
                        onSeeAll: _goToExplore,
                        builder: (shops) => NearbyShopsRail(shops: shops),
                      ),
                    ),

                  if (showRails)
                    SliverToBoxAdapter(
                      child: BudgetPicksSection(areaKey: _railsKey),
                    ),

                  // ── The feed itself ──────────────────────────────────
                  if (searching)
                    ..._searchSlivers(state)
                  else if (filtered)
                    ..._categorySlivers()
                  else
                    ..._feedSlivers(pagingState, fetchNextPage),

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

  /// "Up to 40% off from shops in range" — the headline number is what makes
  /// a deals rail worth opening.
  String _dealsSubtitle(List<Product> deals) {
    var best = 0;
    for (final deal in deals) {
      if (deal.price <= 0) continue;
      final percent =
          (((deal.price - deal.disCountedPrice) / deal.price) * 100).round();
      if (percent > best) best = percent;
    }
    return best > 0
        ? 'Up to $best% off from shops in range'
        : '${deals.length} on discount in range';
  }

  List<Widget> _searchSlivers(CustomerDataLoadedState state) {
    if (state.loadingProducts == true) {
      return [
        SliverToBoxAdapter(child: ShimmerLoading.productGrid(count: 4)),
      ];
    }

    final results = state.searchProducts ?? const <Product>[];
    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          title: 'Search results',
          subtitle: results.isEmpty
              ? 'Nothing matched that'
              : '${results.length} found',
        ),
      ),
      if (results.isEmpty)
        SliverToBoxAdapter(
          child: _EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            message: 'Try a different word, or browse the feed below.',
          ),
        )
      else
        _grid(
          itemCount: results.length,
          builder: (context, index) => _card(results[index], index),
        ),
    ];
  }

  List<Widget> _categorySlivers() {
    final category = _category!;
    final results = _categoryResults;

    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          title: category.name,
          subtitle: results == null
              ? 'Looking through shops near you…'
              : '${results.length} in range · tap the chip again to clear',
          onSeeAll: () =>
              context.pushScreen(() => CategoryScreen(category: category)),
        ),
      ),
      if (results == null)
        SliverToBoxAdapter(child: ShimmerLoading.productGrid(count: 4))
      else if (results.isEmpty)
        SliverToBoxAdapter(
          child: _EmptyState(
            icon: Icons.category_outlined,
            title: 'Nothing in ${category.name} yet',
            message: 'No shop in range stocks this category. '
                'Try another one, or widen your area.',
            actionLabel: 'Show everything',
            onAction: () => _selectCategory(null),
          ),
        )
      else
        _grid(
          itemCount: results.length,
          builder: (context, index) => _card(results[index], index),
        ),
    ];
  }

  List<Widget> _feedSlivers(
    PagingState<int, Product> pagingState,
    VoidCallback fetchNextPage,
  ) {
    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          title: 'Picked for you',
          subtitle: 'Fresh from shops around you',
        ).animateEntrance(index: 3),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        sliver: PagedSliverGrid<int, Product>(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            newPageProgressIndicatorBuilder: (_) => const _PageSpinner(),
            noItemsFoundIndicatorBuilder: (_) => _EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nothing here yet',
              message: 'No products from shops in this area. '
                  'Try a different location.',
              actionLabel: 'Change location',
              onAction: _changeLocation,
            ),
            itemBuilder: (context, item, index) =>
                _card(item, index).animateEntrance(index: index),
          ),
        ),
      ),
    ];
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

/// A curated rail: header, a skeleton while it loads, and nothing at all
/// when the area has none of whatever it lists.
///
/// Hiding an empty rail rather than showing it empty is the whole point — a
/// home feed padded with "no results" blocks is worse than a shorter one.
class _RailSection<T> extends StatelessWidget {
  const _RailSection({
    required this.future,
    required this.title,
    required this.subtitle,
    required this.skeleton,
    required this.builder,
    this.onSeeAll,
  });

  final Future<List<T>> future;
  final String title;
  final String Function(List<T> items) subtitle;
  final Widget skeleton;
  final Widget Function(List<T> items) builder;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final items = snapshot.data ?? <T>[];
        if (!waiting && items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              subtitle: waiting ? 'Looking around you…' : subtitle(items),
              onSeeAll: waiting ? null : onSeeAll,
            ),
            CrossFade(
              state: waiting,
              child: waiting ? skeleton : builder(items),
            ),
          ],
        );
      },
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: ShimmerLoading.line(height: 52),
          ),
          const SizedBox(height: 14),
          // Mirrors the hero: greeting, location row, counter strip.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: ShimmerLoading.line(height: 158),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: ShimmerLoading.line(height: 40),
          ),
          const SizedBox(height: 20),
          ShimmerLoading.productRow(count: 3),
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
