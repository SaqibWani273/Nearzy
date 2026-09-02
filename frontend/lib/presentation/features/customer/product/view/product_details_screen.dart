import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../data/models/product.dart';
import '../../../../../data/models/shop_model/shop_model1.dart';
import '../../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_motion.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../utils/utils.dart';
import '../../../../common/animations/entrance.dart';
import '../../../../common/animations/nearzy_page_route.dart';
import '../../../../common/animations/pressable_scale.dart';
import '../../../../common/widgets/nearzy_network_image.dart';
import '../../../../common/widgets/nearzy_product_card.dart';
import '../../authentication/view/customer_login.dart';
import '../../cart/cart_screen.dart';
import '../../dashboard/view_model/customer_data_bloc.dart';
import '../../shops/shop_details_screen.dart';

/// Product detail: a full-bleed gallery that parallaxes under a sheet of
/// content, with the buy actions pinned to the bottom.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ScrollController _scroll = ScrollController();
  final PageController _gallery = PageController();

  int _imageIndex = 0;

  /// 0 at the top, 1 once the sheet has covered the gallery. Drives the
  /// header's fade from glass-on-photo to solid-on-paper.
  double _collapse = 0;

  Product get product => widget.product;

  static const double _galleryHeight = 400;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _gallery.dispose();
    super.dispose();
  }

  void _onScroll() {
    final next = (_scroll.offset / (_galleryHeight * 0.6)).clamp(0.0, 1.0);
    if ((next - _collapse).abs() > 0.01) setState(() => _collapse = next);
  }

  int? get _discountPercent {
    if (product.disCountedPrice >= product.price || product.price <= 0) {
      return null;
    }
    return (((product.price - product.disCountedPrice) / product.price) * 100)
        .round();
  }

  String _rupees(int paise) {
    final value = paise / 100;
    return '₹${value == value.roundToDouble() ? value.round() : value.toStringAsFixed(2)}';
  }

  Future<bool> _requireLogin() async {
    if (context.read<CustomerDataRepository>().customer != null) return true;
    await context.pushScreen(() => const CustomerLogin());
    return mounted && context.read<CustomerDataRepository>().customer != null;
  }

  Future<void> _addToCart({bool thenOpenCart = false}) async {
    if (!await _requireLogin()) return;
    if (!mounted) return;

    if (!product.available) {
      Utils.showScaffoldMessage(
        message: 'This product is currently out of stock',
        context: context,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    context.read<CustomerDataBloc>().add(
      CustomerDataAddProductToCartEvent(product: product),
    );

    if (thenOpenCart && mounted) {
      context.pushScreen(() => const CartScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: BlocListener<CustomerDataBloc, CustomerDataState>(
        listenWhen: (_, current) =>
            current is CustomerDataLoadedState && current.canAddToCart != null,
        listener: (context, state) {
          final loaded = state as CustomerDataLoadedState;
          if (loaded.canAddToCart == false) {
            _showShopMismatch(context);
          } else if (loaded.canAddToCart == true) {
            Utils.showScaffoldMessage(
              message: 'Added to your bag',
              context: context,
              actionWidget: TextButton(
                onPressed: () => context.pushScreen(() => const CartScreen()),
                child: Text(
                  'View bag',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.lime,
                  ),
                ),
              ),
            );
          }
        },
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // The gallery lives inside the scroll view rather than behind
                // it — a PageView layered under a CustomScrollView never sees
                // a horizontal drag, because the scroll view eats the gesture
                // before it gets there.
                SliverAppBar(
                  expandedHeight: _galleryHeight,
                  collapsedHeight: 0,
                  toolbarHeight: 0,
                  pinned: false,
                  stretch: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.paperDim,
                  flexibleSpace: _Gallery(
                    images: product.images,
                    controller: _gallery,
                    heroTag: 'product-${product.id ?? product.name}',
                    imageIndex: _imageIndex,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                  ),
                ),
                SliverToBoxAdapter(
                  // Pull the sheet up so its rounded corners overlap the
                  // gallery's lower edge.
                  child: Transform.translate(
                    offset: const Offset(0, -AppSpacing.radiusXl),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusXl),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        24,
                        AppSpacing.gutter,
                        140,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StockChip(
                            available: product.available,
                          ).animateEntrance(),
                          const SizedBox(height: 14),
                          Text(
                            product.name,
                            style: AppTextStyles.heading1,
                          ).animateEntrance(index: 1),
                          if (product.brand.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              product.brand,
                              style: AppTextStyles.bodySmall,
                            ).animateEntrance(index: 2),
                          ],
                          const SizedBox(height: 18),
                          _PriceRow(
                            price: _rupees(product.price),
                            discounted: _discountPercent == null
                                ? null
                                : _rupees(product.disCountedPrice),
                            percentOff: _discountPercent,
                            rating: product.rating,
                          ).animateEntrance(index: 3),
                          if (product.colors?.isNotEmpty ?? false) ...[
                            const SizedBox(height: AppSpacing.sectionGap),
                            Text('Colours', style: AppTextStyles.sectionTitle),
                            const SizedBox(height: 12),
                            _ColourRow(colours: product.colors!),
                          ],
                          const SizedBox(height: AppSpacing.sectionGap),
                          Text(
                            'Description',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.completeDescription.isNotEmpty
                                ? product.completeDescription
                                : (product.shortDescription.isNotEmpty
                                      ? product.shortDescription
                                      : 'The shop has not added a description yet.'),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sectionGap),
                          Text('Sold by', style: AppTextStyles.sectionTitle),
                          const SizedBox(height: 12),
                          _ShopCard(
                            shop: product.shop,
                            onTap: () => context.pushScreen(
                              () => ShopDetailsScreen(shop: product.shop),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Floating header ──────────────────────────────────────
            // The heart's state lives in the repository, which is not a
            // Listenable — rebuild off the bloc, which emits on every toggle.
            BlocBuilder<CustomerDataBloc, CustomerDataState>(
              builder: (context, _) => _FloatingHeader(
                collapse: _collapse,
                title: product.name,
                isFavourite: context
                    .read<CustomerDataRepository>()
                    .isFavourite(product.id),
                onBack: () => Navigator.of(context).pop(),
                onFavourite: () => context.read<CustomerDataBloc>().add(
                      CustomerDataToggleFavouriteEvent(product: product),
                    ),
              ),
            ),

            // ── Buy bar ──────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BuyBar(
                available: product.available,
                onAddToCart: _addToCart,
                onBuyNow: () => _addToCart(thenOpenCart: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShopMismatch(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('One shop per order'),
        content: Text(
          'Your bag already has items from another shop. Nearzy orders are '
          'fulfilled by a single local shop, so finish or clear that order '
          'first.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.pushScreen(() => const CartScreen());
            },
            child: const Text('View bag'),
          ),
        ],
      ),
    );
  }
}

/// Swipeable full-bleed image gallery.
class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.images,
    required this.controller,
    required this.heroTag,
    required this.imageIndex,
    required this.onPageChanged,
  });

  final List<String> images;
  final PageController controller;
  final String heroTag;
  final int imageIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      // `stretchModes` empty and no title: this exists purely to get the
      // parallax the collapsing sliver provides for free.
      collapseMode: CollapseMode.parallax,
      background: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.paperDim,
            child: images.isEmpty
                ? const NearzyNetworkImage(
                    url: null,
                    fallbackIcon: Icons.shopping_bag_outlined,
                  )
                : PageView.builder(
                    controller: controller,
                    itemCount: images.length,
                    onPageChanged: onPageChanged,
                    itemBuilder: (context, index) {
                      final image = NearzyNetworkImage(
                        url: images[index],
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.shopping_bag_outlined,
                      );
                      // Only the first frame joins the hero flight — a Hero
                      // per page would produce duplicate tags.
                      return index == 0
                          ? Hero(tag: heroTag, child: image)
                          : image;
                    },
                  ),
          ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.radiusXl + 12,
              child: _GalleryDots(count: images.length, index: imageIndex),
            ),
        ],
      ),
    );
  }
}

class _GalleryDots extends StatelessWidget {
  const _GalleryDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.duration(context, Motion.quick),
            curve: Motion.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.lime
                  : AppColors.card.withValues(alpha: 0.7),
              borderRadius: AppSpacing.borderRadiusFull,
            ),
          ),
      ],
    );
  }
}

/// Back and favourite buttons that fade from glass-on-photo to solid-on-paper.
class _FloatingHeader extends StatelessWidget {
  const _FloatingHeader({
    required this.collapse,
    required this.title,
    required this.isFavourite,
    required this.onBack,
    required this.onFavourite,
  });

  final double collapse;
  final String title;
  final bool isFavourite;
  final VoidCallback onBack;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, top + 8, 12, 8),
        color: AppColors.paper.withValues(alpha: collapse),
        child: Row(
          children: [
            _GlassCircle(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onTap: onBack,
            ),
            Expanded(
              child: Opacity(
                opacity: collapse,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title,
                    style: AppTextStyles.heading4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            FavouriteButton(
              isFavourite: isFavourite,
              onToggle: onFavourite,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: available ? AppColors.successSurface : AppColors.errorSurface,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: available ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            available ? 'In stock' : 'Out of stock',
            style: AppTextStyles.badge.copyWith(
              color: available ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.price,
    required this.discounted,
    required this.percentOff,
    required this.rating,
  });

  final String price;
  final String? discounted;
  final int? percentOff;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(discounted ?? price, style: AppTextStyles.priceLarge),
        if (discounted != null) ...[
          const SizedBox(width: 10),
          Text(
            price,
            style: AppTextStyles.priceStrikethrough.copyWith(fontSize: 15),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Text(
              '$percentOff% off',
              style: AppTextStyles.badge.copyWith(color: AppColors.lime),
            ),
          ),
        ],
        const Spacer(),
        if (rating != null && rating! > 0)
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 17,
                color: AppColors.warning,
              ),
              const SizedBox(width: 3),
              Text(
                rating!.toStringAsFixed(1),
                style: AppTextStyles.labelMedium,
              ),
            ],
          ),
      ],
    );
  }
}

class _ColourRow extends StatefulWidget {
  const _ColourRow({required this.colours});

  final List<String> colours;

  @override
  State<_ColourRow> createState() => _ColourRowState();
}

class _ColourRowState extends State<_ColourRow> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < widget.colours.length; i++)
          PressableScale(
            onTap: () => setState(() => _selected = i),
            scale: 0.94,
            child: AnimatedContainer(
              duration: Motion.duration(context, Motion.quick),
              curve: Motion.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: i == _selected ? AppColors.ink : AppColors.card,
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(
                  color: i == _selected ? AppColors.ink : AppColors.line,
                ),
              ),
              child: Text(
                widget.colours[i],
                style: AppTextStyles.labelSmall.copyWith(
                  color: i == _selected
                      ? AppColors.lime
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop, required this.onTap});

  final ShopModel1 shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusXl,
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusMd,
              child: NearzyNetworkImage(
                url: shop.shopPicUrl.isNotEmpty
                    ? shop.shopPicUrl
                    : shop.ownerPicUrl,
                width: 52,
                height: 52,
                fallbackIcon: Icons.storefront_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.displayName,
                    style: AppTextStyles.heading4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (shop.distanceLabel != null)
                        '${shop.distanceLabel} away',
                      if (shop.address.isNotEmpty) shop.address,
                    ].join(' · '),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyBar extends StatelessWidget {
  const _BuyBar({
    required this.available,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final bool available;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        14,
        AppSpacing.gutter,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppSpacing.shadowElevated,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: available ? onAddToCart : null,
              child: const Text('Add to bag'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: available ? onBuyNow : null,
              child: Text(available ? 'Buy now' : 'Unavailable'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: onTap,
        scale: 0.9,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: AppSpacing.shadowSubtle,
          ),
          child: Icon(icon, size: 19, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Legacy helper kept for callers still importing it from this library.
Widget buildShopDetails(ShopModel1 shop) => Builder(
  builder: (context) => _ShopCard(shop: shop, onTap: () {}),
);
