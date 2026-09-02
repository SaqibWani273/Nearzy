import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/shop_model/shop_model1.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/nearzy_page_route.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/widgets/map/nearzy_map.dart';
import '../../../common/widgets/nearzy_network_image.dart';
import '../shops/shop_details_screen.dart';

/// Nearby shops plotted on a map, with a card carousel locked to the markers:
/// swipe the cards and the camera flies to the matching pin, tap a pin and
/// the carousel scrolls to its card.
class NearbyShopsMapScreen extends StatefulWidget {
  const NearbyShopsMapScreen({
    super.key,
    required this.shops,
    required this.origin,
    this.radiusKm = 15,
  });

  final List<ShopModel1> shops;

  /// Where the customer is browsing from — the map's initial centre.
  final LocationInfo? origin;

  final double radiusKm;

  @override
  State<NearbyShopsMapScreen> createState() => _NearbyShopsMapScreenState();
}

class _NearbyShopsMapScreenState extends State<NearbyShopsMapScreen>
    with TickerProviderStateMixin, AnimatedMapMixin {
  final MapController _map = MapController();
  late final PageController _cards =
      PageController(viewportFraction: 0.86);

  /// Shops that actually carry usable coordinates. A shop at (0,0) would
  /// otherwise drag the whole map into the Atlantic.
  late final List<ShopModel1> _mappable = widget.shops
      .where((s) => s.locationInfo.hasCoordinates)
      .toList();

  int _selected = 0;

  LatLng get _origin {
    final o = widget.origin;
    return (o != null && o.hasCoordinates)
        ? LatLng(o.latitude, o.longtitude)
        : LatLng(
            LocationInfo.defaultValue().latitude,
            LocationInfo.defaultValue().longtitude,
          );
  }

  @override
  void dispose() {
    _cards.dispose();
    _map.dispose();
    super.dispose();
  }

  void _select(int index, {bool fromMarker = false}) {
    if (index < 0 || index >= _mappable.length) return;
    setState(() => _selected = index);

    final shop = _mappable[index];
    animateCameraTo(
      _map,
      LatLng(shop.locationInfo.latitude, shop.locationInfo.longtitude),
      zoom: _map.camera.zoom < 14 ? 15 : _map.camera.zoom,
    );

    if (fromMarker && _cards.hasClients) {
      HapticFeedback.selectionClick();
      _cards.animateToPage(
        index,
        duration: Motion.base,
        curve: Motion.emphasis,
      );
    }
  }

  /// Frames every marker plus the origin, so opening the screen shows the
  /// whole result set rather than an arbitrary zoom level.
  void _fitAll() {
    if (_mappable.isEmpty) return;
    final points = [
      _origin,
      ..._mappable.map((s) =>
          LatLng(s.locationInfo.latitude, s.locationInfo.longtitude)),
    ];
    _map.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(60, 140, 60, 260),
        maxZoom: 16,
      ),
    );
  }

  Future<void> _openDirections(ShopModel1 shop) async {
    final loc = shop.locationInfo;
    // The geo: scheme opens the user's default maps app on Android; iOS
    // falls through to the universal Google Maps URL.
    final uris = [
      Uri.parse('geo:${loc.latitude},${loc.longtitude}'
          '?q=${loc.latitude},${loc.longtitude}'
          '(${Uri.encodeComponent(shop.displayName)})'),
      Uri.parse('https://www.google.com/maps/dir/?api=1'
          '&destination=${loc.latitude},${loc.longtitude}'),
    ];

    for (final uri in uris) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No maps app available on this device')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _origin,
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 19,
              onMapReady: _fitAll,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              const NearzyMapTiles(),

              // Search-radius disc, so "nothing nearby" reads as a coverage
              // fact rather than a bug.
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _origin,
                    radius: widget.radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: AppColors.sage.withValues(alpha: 0.10),
                    borderColor: AppColors.sage.withValues(alpha: 0.45),
                    borderStrokeWidth: 1.2,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _origin,
                    width: 44,
                    height: 44,
                    child: const UserLocationMarker(),
                  ),
                  for (var i = 0; i < _mappable.length; i++)
                    Marker(
                      point: LatLng(
                        _mappable[i].locationInfo.latitude,
                        _mappable[i].locationInfo.longtitude,
                      ),
                      width: 108,
                      height: 64,
                      // Anchor the pin's point at the coordinate.
                      alignment: Alignment.topCenter,
                      child: _AnimatedMarker(
                        index: i,
                        selected: i == _selected,
                        label: _mappable[i].distanceLabel,
                        onTap: () => _select(i, fromMarker: true),
                      ),
                    ),
                ],
              ),

              nearzyMapAttribution(),
            ],
          ),

          // ── Top bar ─────────────────────────────────────────────────
          Positioned(
            top: topInset + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _MapCircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppSpacing.borderRadiusFull,
                      boxShadow: AppSpacing.shadowSoft,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            size: 18, color: AppColors.ink),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_mappable.length} shop'
                                '${_mappable.length == 1 ? '' : 's'} nearby',
                                style: AppTextStyles.labelMedium,
                              ),
                              Text(
                                'Within ${widget.radiusKm.round()} km',
                                style: AppTextStyles.micro,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Fit-all control ─────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: _mappable.isEmpty ? 32 : 214,
            child: _MapCircleButton(
              icon: Icons.center_focus_strong_rounded,
              tooltip: 'Show all shops',
              onTap: () {
                HapticFeedback.lightImpact();
                _fitAll();
              },
            ).animateEntrance(delay: Motion.base, offset: 20),
          ),

          // ── Card carousel ───────────────────────────────────────────
          if (_mappable.isEmpty)
            const Align(
              alignment: Alignment.bottomCenter,
              child: _NoMappableShops(),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              height: 172,
              child: PageView.builder(
                controller: _cards,
                itemCount: _mappable.length,
                padEnds: true,
                onPageChanged: _select,
                itemBuilder: (context, index) {
                  final shop = _mappable[index];
                  return _ShopMapCard(
                    shop: shop,
                    active: index == _selected,
                    onOpen: () => context.pushScreen(
                      () => ShopDetailsScreen(shop: shop),
                    ),
                    onDirections: () => _openDirections(shop),
                  );
                },
              ).animateEntrance(delay: Motion.quick, offset: 40),
            ),
        ],
      ),
    );
  }
}

/// A pin that drops in on first build and scales when selected.
class _AnimatedMarker extends StatelessWidget {
  const _AnimatedMarker({
    required this.index,
    required this.selected,
    required this.onTap,
    this.label,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: selected ? 1.16 : 1.0,
        duration: Motion.duration(context, Motion.quick),
        curve: Motion.spring,
        alignment: Alignment.bottomCenter,
        child: Align(
          alignment: Alignment.topCenter,
          child: ShopMapMarker(selected: selected, label: label),
        ),
      ),
    ).animateEntrance(
      index: index,
      offset: 24,
      duration: Motion.base,
      curve: Motion.spring,
    );
  }
}

/// One card in the map carousel.
class _ShopMapCard extends StatelessWidget {
  const _ShopMapCard({
    required this.shop,
    required this.active,
    required this.onOpen,
    required this.onDirections,
  });

  final ShopModel1 shop;
  final bool active;
  final VoidCallback onOpen;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: Motion.duration(context, Motion.quick),
      curve: Motion.easeOut,
      // Inactive cards sit lower, which reads as depth while swiping.
      padding: EdgeInsets.fromLTRB(7, active ? 0 : 10, 7, active ? 10 : 0),
      child: PressableScale(
        onTap: onOpen,
        scale: 0.98,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppSpacing.borderRadiusXl,
            boxShadow: AppSpacing.shadowElevated,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: AppSpacing.borderRadiusMd,
                    child: NearzyNetworkImage(
                      url: shop.shopPicUrl,
                      width: 62,
                      height: 62,
                      fallbackIcon: Icons.storefront_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                shop.displayName,
                                style: AppTextStyles.heading4,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (shop.isVerified == true) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded,
                                  size: 15, color: AppColors.info),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          shop.address.isNotEmpty
                              ? shop.address
                              : shop.locationInfo.shortAddress,
                          style: AppTextStyles.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (shop.distanceLabel != null) ...[
                          const SizedBox(height: 6),
                          _DistancePill(label: shop.distanceLabel!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _CardAction(
                      icon: Icons.directions_outlined,
                      label: 'Directions',
                      onTap: onDirections,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CardAction(
                      icon: Icons.storefront_outlined,
                      label: 'View shop',
                      primary: true,
                      onTap: onOpen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistancePill extends StatelessWidget {
  const _DistancePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.limeSurface,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, size: 11, color: AppColors.ink),
          const SizedBox(width: 4),
          Text('$label away',
              style: AppTextStyles.badge.copyWith(color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.lime : AppColors.textPrimary;
    return PressableScale(
      onTap: onTap,
      scale: 0.95,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: primary ? AppColors.ink : AppColors.paper,
          borderRadius: AppSpacing.borderRadiusFull,
          border: primary ? null : Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.labelSmall.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

class _NoMappableShops extends StatelessWidget {
  const _NoMappableShops();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppSpacing.shadowElevated,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.sageSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wrong_location_outlined,
                color: AppColors.sageDeep),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nothing to plot here', style: AppTextStyles.heading4),
                const SizedBox(height: 3),
                Text(
                  'No shops in this area have shared their exact location yet.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animateEntrance(offset: 30);
  }
}

class _MapCircleButton extends StatelessWidget {
  const _MapCircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: onTap,
        scale: 0.92,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            boxShadow: AppSpacing.shadowSoft,
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
