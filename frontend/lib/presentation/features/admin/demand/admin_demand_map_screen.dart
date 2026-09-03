import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/models/demand_heatmap.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/widgets/map/nearzy_map.dart';

/// Where the orders are actually coming from.
///
/// Shop pins say where supply already exists; this plots delivery addresses,
/// which is the question the admin is asking when deciding where the discovery
/// radius should be widened. A dense patch with no shops nearby is exactly the
/// gap worth filling.
///
/// Orders only — search queries are not logged anywhere in the backend, so
/// demand that never converted is invisible here rather than estimated.
class AdminDemandMapScreen extends StatefulWidget {
  const AdminDemandMapScreen({super.key});

  @override
  State<AdminDemandMapScreen> createState() => _AdminDemandMapScreenState();
}

class _AdminDemandMapScreenState extends State<AdminDemandMapScreen> {
  final _map = MapController();

  late Future<DemandHeatmap> _heatmap;
  int _days = 30;

  static const List<int> _windows = [7, 30, 90, 365];

  @override
  void initState() {
    super.initState();
    _heatmap = ApiService.fetchDemandHeatmap(days: _days);
  }

  void _setWindow(int days) {
    if (days == _days) return;
    setState(() {
      _days = days;
      _heatmap = ApiService.fetchDemandHeatmap(days: days);
    });
  }

  /// Frames every point. Order density here spans the country, so opening on a
  /// fixed city centre would show an empty map most of the time.
  void _fitAll(DemandHeatmap data) {
    if (data.points.isEmpty) return;
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(
          data.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        ),
        padding: const EdgeInsets.all(64),
        maxZoom: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: FutureBuilder<DemandHeatmap>(
        future: _heatmap,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final loading = snapshot.connectionState == ConnectionState.waiting;

          // Refit whenever a new window lands, after this frame has laid out.
          if (data != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _fitAll(data);
            });
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: const MapOptions(
                  initialCenter: LatLng(22.97, 78.65),
                  initialZoom: 4.2,
                  minZoom: 3,
                  maxZoom: 19,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  // muted: true is load-bearing — additive blobs over
                  // full-colour OSM tiles read as mud.
                  const NearzyMapTiles(),
                  if (data != null && data.points.isNotEmpty)
                    DemandHeatLayer(
                      maxWeight: data.maxOrders,
                      points: [
                        for (final p in data.points)
                          (
                            point: LatLng(p.latitude, p.longitude),
                            weight: p.orders,
                          ),
                      ],
                    ),
                  nearzyMapAttribution(),
                ],
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      data: data,
                      loading: loading,
                      failed: snapshot.hasError,
                    ),
                    _WindowPicker(
                      windows: _windows,
                      selected: _days,
                      onSelect: _setWindow,
                    ),
                    const Spacer(),
                    if (data != null && data.points.isNotEmpty)
                      _Legend(maxOrders: data.maxOrders),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.data,
    required this.loading,
    required this.failed,
  });

  final DemandHeatmap? data;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final String subtitle;
    if (loading) {
      subtitle = 'Loading…';
    } else if (failed) {
      subtitle = "Couldn't load demand data";
    } else if (data == null || data!.isEmpty) {
      subtitle = 'No orders with a mapped address in this window';
    } else {
      subtitle = '${data!.totalOrders} '
          '${data!.totalOrders == 1 ? 'order' : 'orders'} · '
          '${data!.points.length} areas';
    }

    return Container(
      margin: const EdgeInsets.all(AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppSpacing.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demand', style: AppTextStyles.heading3),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _WindowPicker extends StatelessWidget {
  const _WindowPicker({
    required this.windows,
    required this.selected,
    required this.onSelect,
  });

  final List<int> windows;
  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        itemCount: windows.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final days = windows[index];
          final active = days == selected;
          return GestureDetector(
            onTap: () => onSelect(days),
            child: AnimatedContainer(
              duration: AppSpacing.durationFast,
              curve: AppSpacing.curveDefault,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.card,
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(
                  color: active ? AppColors.ink : AppColors.line,
                ),
              ),
              child: Text(
                days >= 365 ? '1 year' : '$days days',
                style: AppTextStyles.labelSmall.copyWith(
                  color: active ? AppColors.paper : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.maxOrders});

  final int maxOrders;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.base),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppSpacing.shadowSubtle,
      ),
      child: Row(
        children: [
          Text('1', style: AppTextStyles.caption),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: AppSpacing.borderRadiusFull,
                gradient: LinearGradient(
                  colors: [
                    AppColors.sageDeep.withValues(alpha: 0.35),
                    AppColors.lime,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$maxOrders', style: AppTextStyles.caption),
          const SizedBox(width: AppSpacing.sm),
          Text('orders / area', style: AppTextStyles.caption),
        ],
      ),
    ).animateEntrance();
  }
}
