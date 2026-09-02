import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../../data/models/place_suggestion.dart';
import '../../../../data/models/shop_model/shop_model1.dart';
import '../../../../services/geo_locator_service.dart';
import '../../../../services/location_search_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/widgets/map/nearzy_map.dart';

/// Full-screen location chooser: search by name, drop a pin on the map, or
/// snap to the device's GPS fix.
///
/// Pops the chosen [LocationInfo], or null if the user backs out.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  /// Where the map opens. Falls back to the app's default city.
  final LocationInfo? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with TickerProviderStateMixin, AnimatedMapMixin {
  final MapController _map = MapController();
  final TextEditingController _query = TextEditingController();
  final FocusNode _queryFocus = FocusNode();

  Timer? _debounce;
  Timer? _reverseDebounce;

  List<PlaceSuggestion> _suggestions = const [];
  bool _searching = false;
  bool _resolving = false;
  bool _locating = false;

  late LatLng _center;
  LocationInfo? _resolved;

  /// True while the user is dragging, so the pin can lift off the map.
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    final start = widget.initial ?? LocationInfo.defaultValue();
    _center = LatLng(start.latitude, start.longtitude);
    _resolved = start;
    _query.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _reverseDebounce?.cancel();
    _query.dispose();
    _queryFocus.dispose();
    _map.dispose();
    super.dispose();
  }

  // ── Search ──────────────────────────────────────────────────────────

  void _onQueryChanged() {
    _debounce?.cancel();
    final text = _query.text.trim();

    if (text.length < 3) {
      if (_suggestions.isNotEmpty || _searching) {
        setState(() {
          _suggestions = const [];
          _searching = false;
        });
      }
      return;
    }

    // Nominatim is rate-limited to ~1 req/s, and typing outpaces that by an
    // order of magnitude — debounce rather than firing per keystroke.
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(text));
  }

  Future<void> _search(String text) async {
    final results = await LocationSearchService.search(
      text,
      nearLat: _center.latitude,
      nearLng: _center.longitude,
    );
    if (!mounted || _query.text.trim() != text) return;
    setState(() {
      _suggestions = results;
      _searching = false;
    });
  }

  void _selectSuggestion(PlaceSuggestion place) {
    HapticFeedback.selectionClick();
    _queryFocus.unfocus();
    final target = LatLng(place.latitude, place.longitude);

    setState(() {
      _suggestions = const [];
      _query.text = place.title;
      _resolved = LocationSearchService.toLocationInfo(place);
      _center = target;
    });

    animateCameraTo(_map, target, zoom: 15);
  }

  // ── Map pin ─────────────────────────────────────────────────────────

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart) {
      setState(() => _dragging = true);
      return;
    }

    // Every gesture end lands here; only re-geocode once the camera settles.
    final settled =
        event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd ||
        event is MapEventScrollWheelZoom;
    if (!settled) return;

    setState(() {
      _dragging = false;
      _center = event.camera.center;
    });
    _scheduleReverseGeocode();
  }

  void _scheduleReverseGeocode() {
    _reverseDebounce?.cancel();
    setState(() => _resolving = true);
    _reverseDebounce = Timer(const Duration(milliseconds: 600), () async {
      final target = _center;
      final info = await LocationSearchService.reverse(
        target.latitude,
        target.longitude,
      );
      // A newer drag may have landed while this was in flight.
      if (!mounted || target != _center) return;
      setState(() {
        _resolved = info;
        _resolving = false;
      });
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final info = await GeoLocatorService.fetchLocationInfo(null);
      if (!mounted) return;
      final target = LatLng(info.latitude, info.longtitude);
      setState(() {
        _resolved = info;
        _center = target;
        _query.clear();
        _suggestions = const [];
      });
      animateCameraTo(_map, target, zoom: 16);
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('permission')
                ? 'Location permission is off. Enable it in Settings, or pick a spot on the map.'
                : "Couldn't get your location. Pick a spot on the map instead.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    final result =
        _resolved ??
        LocationInfo(
          completeAddress:
              '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
          shortAddress: 'Dropped pin',
          latitude: _center.latitude,
          longtitude: _center.longitude,
        );
    // The card shows whatever the map is centred on, so trust the camera over
    // a stale geocode.
    Navigator.of(context).pop(
      result.copyWith(
        latitude: _center.latitude,
        longtitude: _center.longitude,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              minZoom: 3,
              maxZoom: 19,
              onMapEvent: _onMapEvent,
              onTap: (_, _) => _queryFocus.unfocus(),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [const NearzyMapTiles(), nearzyMapAttribution()],
          ),

          // The pin is pinned to the viewport centre rather than to a
          // coordinate, so dragging the map moves the world under it.
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                // Lift by half the pin's height so its point, not its middle,
                // marks the centre.
                offset: const Offset(0, -22),
                child: _CenterPin(lifted: _dragging),
              ),
            ),
          ),

          _SearchOverlay(
            controller: _query,
            focusNode: _queryFocus,
            searching: _searching,
            suggestions: _suggestions,
            onSelect: _selectSuggestion,
            onBack: () => Navigator.of(context).pop(),
            onClear: () {
              _query.clear();
              _queryFocus.requestFocus();
            },
          ),

          // ── Confirm card ────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ConfirmCard(
              address: _resolved,
              resolving: _resolving,
              locating: _locating,
              bottomInset: bottomInset,
              onUseCurrent: _locating ? null : _useCurrentLocation,
              onConfirm: _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

/// The draggable centre pin. Lifts and casts a shadow while the map moves.
class _CenterPin extends StatelessWidget {
  const _CenterPin({required this.lifted});

  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSlide(
          offset: Offset(0, lifted ? -0.18 : 0),
          duration: Motion.duration(context, Motion.quick),
          curve: Motion.spring,
          child: const ShopMapMarker(selected: true, icon: Icons.place_rounded),
        ),
        // Ground shadow — the cue that tells the eye the pin has lifted.
        AnimatedContainer(
          duration: Motion.duration(context, Motion.quick),
          curve: Motion.easeOut,
          width: lifted ? 16 : 10,
          height: lifted ? 5 : 3,
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: lifted ? 0.18 : 0.3),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

/// Floating search field plus its results list.
class _SearchOverlay extends StatelessWidget {
  const _SearchOverlay({
    required this.controller,
    required this.focusNode,
    required this.searching,
    required this.suggestions,
    required this.onSelect,
    required this.onBack,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final List<PlaceSuggestion> suggestions;
  final ValueChanged<PlaceSuggestion> onSelect;
  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _CircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppSpacing.borderRadiusFull,
                      boxShadow: AppSpacing.shadowSoft,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 18),
                        const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textInputAction: TextInputAction.search,
                            style: AppTextStyles.inputText,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Search area, street or landmark',
                              hintStyle: AppTextStyles.inputHint,
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: Motion.duration(context, Motion.quick),
                          child: searching
                              ? const Padding(
                                  key: ValueKey('spinner'),
                                  padding: EdgeInsets.only(right: 18),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                )
                              : ValueListenableBuilder(
                                  key: const ValueKey('clear'),
                                  valueListenable: controller,
                                  builder: (context, value, _) =>
                                      value.text.isEmpty
                                      ? const SizedBox(width: 18)
                                      : IconButton(
                                          onPressed: onClear,
                                          tooltip: 'Clear search',
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10, left: 54),
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppSpacing.borderRadiusLg,
                  boxShadow: AppSpacing.shadowElevated,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 52,
                    color: AppColors.line,
                  ),
                  itemBuilder: (context, index) {
                    final place = suggestions[index];
                    return _SuggestionTile(
                      place: place,
                      index: index,
                      onTap: () => onSelect(place),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.place,
    required this.index,
    required this.onTap,
  });

  final PlaceSuggestion place;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.sageSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.place_outlined,
                size: 17,
                color: AppColors.sageDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    style: AppTextStyles.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      place.subtitle,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animateEntrance(index: index, offset: 8, duration: Motion.quick);
  }
}

/// Bottom card showing the resolved address and the two ways out.
class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.address,
    required this.resolving,
    required this.locating,
    required this.bottomInset,
    required this.onUseCurrent,
    required this.onConfirm,
  });

  final LocationInfo? address;
  final bool resolving;
  final bool locating;
  final double bottomInset;
  final VoidCallback? onUseCurrent;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        boxShadow: AppSpacing.shadowElevated,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.limeSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.place_rounded,
                  size: 20,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deliver around', style: AppTextStyles.overline),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: Motion.duration(context, Motion.base),
                      child: resolving
                          ? Text(
                              'Finding address…',
                              key: const ValueKey('resolving'),
                              style: AppTextStyles.bodySmall,
                            )
                          : Column(
                              key: ValueKey(address?.completeAddress),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address?.shortAddress ?? 'Dropped pin',
                                  style: AppTextStyles.heading4,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (address?.completeAddress.isNotEmpty ??
                                    false) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    address!.completeAddress,
                                    style: AppTextStyles.caption,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUseCurrent,
                  icon: locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(locating ? 'Locating…' : 'Current'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  child: const Text('Confirm location'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
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
    );
  }
}
