import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

/// The one place the app's tile source is configured.
///
/// OpenStreetMap's own tile server is used because it is free, needs no API
/// key, and has no sign-up — the app ships without the operator provisioning
/// a maps billing account. (CARTO's basemaps look better out of the box but
/// now stamp "API KEY REQUIRED" across every tile, and Stadia/Mapbox/Google
/// all require a key before the first request.)
///
/// Raw OSM tiles are too saturated to overlay a brand on, so [_tint] mutes
/// them at paint time: the map becomes a quiet grey-green ground and the lime
/// markers carry all the colour. That styling is ours, applied on-device — no
/// derived tile is stored or redistributed.
class NearzyMapTiles extends StatelessWidget {
  const NearzyMapTiles({super.key, this.muted = true});

  /// Set false where the map itself is the subject and full colour helps.
  final bool muted;

  static const String _urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// A luminance-preserving desaturation to ~30%, with blue held back from
  /// the collapse so water still reads as water against the sage ground.
  /// Derived and eyeballed against real Srinagar tiles rather than guessed —
  /// a flat grey filter makes lakes and parks indistinguishable.
  static const ColorFilter _tint = ColorFilter.matrix(<double>[
    0.431, 0.480, 0.048, 0, -4, //
    0.148, 0.792, 0.050, 0, -2, //
    0.120, 0.400, 0.480, 0, -4, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: _urlTemplate,
      // Required by the OSM tile usage policy: identify the app so they can
      // reach the operator rather than silently blocking it.
      userAgentPackageName: 'app.nearzy.mca_project',
      // OSM serves up to z19; asking for 20 returns 404s.
      maxNativeZoom: 19,
      maxZoom: 19,
      tileProvider: NetworkTileProvider(),
      tileBuilder: muted
          ? (context, tileWidget, tile) =>
              ColorFiltered(colorFilter: _tint, child: tileWidget)
          : null,
    );
  }
}

/// Attribution required by the OSM/CARTO tile licences. Not optional.
Widget nearzyMapAttribution() => RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: [
        TextSourceAttribution(
          '© OpenStreetMap contributors',
          textStyle: AppTextStyles.micro,
          onTap: null,
        ),
      ],
    );

/// The shop pin: a rounded lime-on-ink teardrop that scales up and gains a
/// halo when selected.
class ShopMapMarker extends StatelessWidget {
  const ShopMapMarker({
    super.key,
    required this.selected,
    this.label,
    this.icon = Icons.storefront_rounded,
  });

  final bool selected;

  /// Rendered inside the pin when short enough — a price, a count, an index.
  final String? label;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.lime : AppColors.ink;
    final foreground = selected ? AppColors.ink : AppColors.lime;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? 9 : 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.card, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: selected ? 0.35 : 0.2),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: AppTextStyles.badge.copyWith(color: foreground),
                ),
              ],
            ],
          ),
        ),
        // The stem, so the pin points at its coordinate rather than floating
        // over it.
        Transform.translate(
          offset: const Offset(0, -2),
          child: CustomPaint(
            size: const Size(10, 7),
            painter: _PinStem(color: AppColors.card),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -4),
          child: CustomPaint(
            size: const Size(6, 5),
            painter: _PinStem(color: background),
          ),
        ),
      ],
    );
  }
}

class _PinStem extends CustomPainter {
  const _PinStem({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinStem old) => old.color != color;
}

/// The customer's own position: a lime dot with a slow outward pulse.
class UserLocationMarker extends StatefulWidget {
  const UserLocationMarker({super.key});

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44 * (0.4 + _pulse.value * 0.6),
              height: 44 * (0.4 + _pulse.value * 0.6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.info.withValues(
                  alpha: 0.22 * (1 - _pulse.value),
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.info,
                border: Border.all(color: AppColors.card, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Smoothly flies the camera instead of teleporting it.
///
/// `MapController.move` is instantaneous, which makes "recentre" and
/// "select a shop" feel like a cut. This tweens both centre and zoom.
mixin AnimatedMapMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  AnimationController? _cameraController;

  void animateCameraTo(
    MapController controller,
    LatLng destination, {
    double? zoom,
    Duration duration = const Duration(milliseconds: 620),
    Curve curve = Curves.easeOutQuint,
  }) {
    final camera = controller.camera;
    final latTween =
        Tween<double>(begin: camera.center.latitude, end: destination.latitude);
    final lngTween = Tween<double>(
        begin: camera.center.longitude, end: destination.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: zoom ?? camera.zoom);

    _cameraController?.dispose();
    final animation = AnimationController(vsync: this, duration: duration);
    _cameraController = animation;

    final curved = CurvedAnimation(parent: animation, curve: curve);
    void tick() => controller.move(
          LatLng(latTween.evaluate(curved), lngTween.evaluate(curved)),
          zoomTween.evaluate(curved),
        );

    animation
      ..addListener(tick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          animation.dispose();
          if (identical(_cameraController, animation)) {
            _cameraController = null;
          }
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }
}

/// A density overlay for weighted points, drawn straight onto the map canvas.
///
/// `flutter_map` has no heatmap primitive, so this is a custom layer. It sits
/// inside a `FlutterMap`'s `children` like any other layer and reprojects on
/// every camera change, which is what keeps the blobs pinned to the ground
/// rather than to the screen.
///
/// The muted tile filter in [NearzyMapTiles] is what makes this legible —
/// additive warm blobs over full-colour OSM tiles read as mud, so leave
/// `muted: true` under it.
class DemandHeatLayer extends StatelessWidget {
  const DemandHeatLayer({
    super.key,
    required this.points,
    required this.maxWeight,
    this.radius = 44,
  });

  /// `(position, weight)` pairs. Weight is in the same unit as [maxWeight].
  final List<({LatLng point, int weight})> points;

  /// The busiest cell, so intensity is relative to the real peak rather than
  /// to whatever happens to be on screen.
  final int maxWeight;

  /// Blob radius in logical pixels at the current zoom.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    // Project once per frame, in the layer, rather than per blob in the
    // painter — the painter then only has to draw.
    final projected = <({Offset offset, double intensity})>[];
    for (final entry in points) {
      final screen = camera.latLngToScreenOffset(entry.point);
      projected.add((
        offset: screen,
        intensity: maxWeight <= 0 ? 0 : (entry.weight / maxWeight).clamp(0.0, 1.0),
      ));
    }

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _HeatPainter(blobs: projected, radius: radius),
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  const _HeatPainter({required this.blobs, required this.radius});

  final List<({Offset offset, double intensity})> blobs;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (blobs.isEmpty) return;

    // A saveLayer with `plus` blending inside it: overlapping blobs add up, so
    // two nearby cells read hotter than either alone — which is the whole
    // point of a heat map — without the addition leaking onto the tiles below.
    canvas.saveLayer(Offset.zero & size, Paint());

    for (final blob in blobs) {
      // Cheap cull: a blob whose disc cannot touch the viewport costs nothing.
      if (blob.offset.dx < -radius ||
          blob.offset.dy < -radius ||
          blob.offset.dx > size.width + radius ||
          blob.offset.dy > size.height + radius) {
        continue;
      }

      // Scaled so a single order is still visible while the peak is not a
      // solid disc. sqrt keeps the mid-range from collapsing toward zero.
      final strength = 0.28 + 0.62 * math.sqrt(blob.intensity);
      final blobRadius = radius * (0.55 + 0.45 * blob.intensity);

      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          blob.offset,
          blobRadius,
          [
            _hot.withValues(alpha: strength),
            _warm.withValues(alpha: strength * 0.45),
            _warm.withValues(alpha: 0),
          ],
          const [0, 0.55, 1],
        );

      canvas.drawCircle(blob.offset, blobRadius, paint);
    }

    canvas.restore();
  }

  /// Lime at the peak and sage at the fringe: the same two colours the rest of
  /// the map already uses, rather than importing a rainbow ramp that would
  /// belong to no other screen.
  static const Color _hot = AppColors.lime;
  static const Color _warm = AppColors.sageDeep;

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.radius != radius || old.blobs != blobs;
}
