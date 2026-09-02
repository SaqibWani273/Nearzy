import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/product.dart';
import '../../../../data/models/shop_model/shop_model1.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/nearzy_page_route.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/widgets/map/nearzy_map.dart';
import '../../../common/widgets/nearzy_network_image.dart';
import '../../../common/widgets/nearzy_product_card.dart';
import '../../../common/widgets/shimmer_loading.dart';
import '../product/view/product_details_screen.dart';

/// A shop's storefront: parallax cover, contact actions, a map of where it
/// actually is, and its catalogue.
class ShopDetailsScreen extends StatefulWidget {
  const ShopDetailsScreen({super.key, required this.shop});

  final ShopModel1 shop;

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  late final Future<List<Product>> _products = widget.shop.id == null
      ? Future.value(const <Product>[])
      : ApiService.fetchProductsByShopId(widget.shop.id!);

  ShopModel1 get shop => widget.shop;

  Future<void> _launch(Uri uri, String failureMessage) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  void _call() {
    if (shop.phoneNumber.isEmpty) return;
    _launch(Uri.parse('tel:${shop.phoneNumber}'), 'No dialler on this device');
  }

  void _directions() {
    final loc = shop.locationInfo;
    _launch(
      Uri.parse('https://www.google.com/maps/dir/?api=1'
          '&destination=${loc.latitude},${loc.longtitude}'),
      'No maps app available',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = shop.locationInfo.hasCoordinates;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _ShopCoverHeader(shop: shop),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                20,
                AppSpacing.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleBlock(shop: shop).animateEntrance(),
                  const SizedBox(height: 18),
                  _ActionRow(
                    onCall: shop.phoneNumber.isEmpty ? null : _call,
                    onDirections: hasLocation ? _directions : null,
                  ).animateEntrance(index: 1),
                ],
              ),
            ),
          ),

          if (shop.description.trim().isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sectionGap,
                  AppSpacing.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    Text(shop.description, style: AppTextStyles.bodyMedium),
                  ],
                ).animateEntrance(index: 2),
              ),
            ),

          if (hasLocation)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sectionGap,
                  AppSpacing.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Where to find it',
                            style: AppTextStyles.sectionTitle),
                        const Spacer(),
                        if (shop.distanceLabel != null)
                          Text('${shop.distanceLabel} away',
                              style: AppTextStyles.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MiniMap(shop: shop, onOpen: _directions),
                  ],
                ).animateEntrance(index: 3),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sectionGap,
                AppSpacing.gutter,
                12,
              ),
              child: Text('From this shop', style: AppTextStyles.sectionTitle),
            ),
          ),

          FutureBuilder<List<Product>>(
            future: _products,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: ShimmerLoading.productGrid(count: 4),
                );
              }

              final products = snapshot.data ?? const <Product>[];
              if (products.isEmpty) {
                return const SliverToBoxAdapter(child: _NoProducts());
              }

              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
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
                        imageUrl:
                            product.images.isNotEmpty ? product.images.first : '',
                        priceInPaise: product.price,
                        discountedPriceInPaise:
                            product.disCountedPrice < product.price
                                ? product.disCountedPrice
                                : null,
                        rating: product.rating,
                        shopName: shop.displayName,
                        heroTag: 'product-${product.id ?? index}',
                        onTap: () => context.pushScreen(
                          () => ProductDetailsScreen(product: product),
                        ),
                      ).animateEntrance(index: index);
                    },
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

/// Collapsing cover image with a parallax scroll and a title that cross-fades
/// into the collapsed bar.
class _ShopCoverHeader extends StatelessWidget {
  const _ShopCoverHeader({required this.shop});

  final ShopModel1 shop;

  @override
  Widget build(BuildContext context) {
    const expanded = 280.0;

    return SliverAppBar(
      expandedHeight: expanded,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _GlassButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final collapsed =
              MediaQuery.of(context).padding.top + kToolbarHeight;
          // 0 when fully expanded, 1 when fully collapsed.
          final t =
              ((expanded - top) / (expanded - collapsed)).clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
            title: Opacity(
              opacity: t,
              child: Text(
                shop.displayName,
                style: AppTextStyles.heading4,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Parallax: the image drifts at ~0.4x scroll speed.
                Transform.translate(
                  offset: Offset(0, (expanded - top) * 0.4),
                  child: Hero(
                    tag: 'shop-${shop.id ?? shop.displayName}',
                    child: NearzyNetworkImage(
                      url: shop.shopPicUrl,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.storefront_rounded,
                      semanticLabel: shop.displayName,
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.imageScrim),
                ),
                // Fade to paper as the bar collapses, so the pinned title has
                // a legible ground.
                Opacity(
                  opacity: t,
                  child: Container(color: AppColors.paper),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.shop});

  final ShopModel1 shop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(shop.displayName, style: AppTextStyles.heading1),
            ),
            if (shop.isVerified == true) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 13, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text('Verified',
                        style: AppTextStyles.badge
                            .copyWith(color: AppColors.info)),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place_outlined,
                size: 15, color: AppColors.textTertiary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                shop.address.isNotEmpty
                    ? shop.address
                    : shop.locationInfo.shortAddress,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
              ),
            ),
          ],
        ),
        if (shop.categories.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in shop.categories.take(6))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.sageSurface,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    category,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.sageDeep),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onCall, required this.onDirections});

  final VoidCallback? onCall;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: const Text('Directions'),
          ),
        ),
        const SizedBox(width: 12),
        _GhostButton(
          icon: Icons.call_outlined,
          tooltip: 'Call shop',
          onTap: onCall,
        ),
      ],
    );
  }
}

/// Non-interactive map preview. Tapping hands off to the real maps app rather
/// than opening a second pannable map inside a scroll view, which fights the
/// parent for gestures.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.shop, required this.onOpen});

  final ShopModel1 shop;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final point =
        LatLng(shop.locationInfo.latitude, shop.locationInfo.longtitude);

    return PressableScale(
      onTap: onOpen,
      scale: 0.99,
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusXl,
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  const NearzyMapTiles(),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 60,
                        height: 60,
                        alignment: Alignment.topCenter,
                        child: const ShopMapMarker(selected: true),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppSpacing.borderRadiusFull,
                    boxShadow: AppSpacing.shadowSoft,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.open_in_new_rounded,
                          size: 13, color: AppColors.ink),
                      const SizedBox(width: 5),
                      Text('Open in Maps', style: AppTextStyles.labelSmall),
                    ],
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

class _NoProducts extends StatelessWidget {
  const _NoProducts();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: 32,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 28, color: AppColors.sage),
          ),
          const SizedBox(height: 16),
          Text('Nothing listed yet', style: AppTextStyles.heading4),
          const SizedBox(height: 6),
          Text(
            "This shop hasn't published any products.",
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animateEntrance();
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
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

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: onTap,
        scale: 0.92,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.4 : 1,
          duration: Motion.duration(context, Motion.quick),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppSpacing.borderRadiusFull,
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
