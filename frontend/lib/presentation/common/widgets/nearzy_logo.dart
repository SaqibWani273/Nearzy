import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';

/// The Nearzy mark: a map pin whose body is a storefront awning, with the
/// pin's void reading as an open doorway.
///
/// Drawn rather than shipped as a bitmap so it stays sharp from a 16px
/// app-bar glyph up to the launch screen, and so it can recolour itself for
/// ink and paper backgrounds without a second asset.
class NearzyMark extends StatelessWidget {
  const NearzyMark({
    super.key,
    this.size = 40,
    this.color = AppColors.ink,
    this.accent = AppColors.lime,
  });

  final double size;

  /// The pin body.
  final Color color;

  /// The awning and doorway highlight.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarkPainter(color: color, accent: accent),
        isComplex: true,
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Everything below is authored on a 100×100 grid and scaled, so the
    // proportions hold at any rendered size.
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);

    final body = Paint()..color = color;
    final awning = Paint()..color = accent;

    // ── Pin silhouette ────────────────────────────────────────────────
    // A circle of radius 34 at (50,40) tangent-blended into a point at
    // (50, 96). Tangent points are computed so the join is smooth rather
    // than the kinked "teardrop" a naive quadratic gives.
    const cx = 50.0, cy = 40.0, r = 34.0;
    const tipY = 95.0;
    final d = tipY - cy;
    final alpha = math.acos(r / d); // half-angle of the tangent lines
    final tangentX = r * math.sin(alpha);
    final tangentY = cy + r * math.cos(alpha);

    final pin = Path()
      ..moveTo(cx, tipY)
      ..lineTo(cx - tangentX, tangentY)
      ..arcTo(
        Rect.fromCircle(center: const Offset(cx, cy), radius: r),
        math.pi / 2 + alpha, // start at the left tangent point
        2 * math.pi - 2 * alpha, // sweep the long way round the head
        false,
      )
      ..close();

    // ── Doorway ───────────────────────────────────────────────────────
    // Subtracted from the silhouette rather than painted over it, so the
    // background shows through. That negative space is what keeps the mark
    // legible down at a 16px app-bar glyph.
    final door = Path()
      ..moveTo(cx - 10.0, 70)
      ..lineTo(cx - 10.0, 52)
      ..arcToPoint(
        const Offset(cx + 10.0, 52),
        radius: const Radius.circular(10.0),
        clockwise: true,
      )
      ..lineTo(cx + 10.0, 70)
      ..close();

    canvas.drawPath(Path.combine(PathOperation.difference, pin, door), body);

    // ── Awning ────────────────────────────────────────────────────────
    // A scalloped stripe across the head, intersected with the silhouette so
    // it can never spill past the edge.
    const awningTop = 25.0;
    const awningBottom = 40.0;
    const scallops = 4;
    const scallopWidth = 2 * r / scallops;

    final stripe = Path()..moveTo(cx - r, awningTop);
    for (var i = 0; i < scallops; i++) {
      final startX = cx - r + i * scallopWidth;
      stripe.lineTo(startX, awningBottom - 4);
      stripe.quadraticBezierTo(
        startX + scallopWidth / 2,
        awningBottom + 5,
        startX + scallopWidth,
        awningBottom - 4,
      );
    }
    stripe
      ..lineTo(cx + r, awningTop)
      ..close();

    canvas.drawPath(
      Path.combine(PathOperation.intersect, stripe, pin),
      awning,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.color != color || old.accent != accent;
}

/// Mark plus wordmark, locked to the correct optical relationship.
class NearzyLogo extends StatelessWidget {
  const NearzyLogo({
    super.key,
    this.size = 32,
    this.onInk = false,
    this.showWordmark = true,
  });

  final double size;

  /// Recolours for a dark background.
  final bool onInk;

  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final markColor = onInk ? AppColors.paper : AppColors.ink;
    final textColor = onInk ? AppColors.paper : AppColors.ink;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NearzyMark(size: size, color: markColor),
        if (showWordmark) ...[
          SizedBox(width: size * 0.22),
          Text(
            'Nearzy',
            style: GoogleFonts.plusJakartaSans(
              fontSize: size * 0.72,
              fontWeight: FontWeight.w800,
              letterSpacing: -size * 0.028,
              color: textColor,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

/// The launch/splash lockup: the mark drops in, the wordmark fades up behind
/// it, and a hairline ring pulses outward like a location ping.
class NearzySplashLogo extends StatefulWidget {
  const NearzySplashLogo({super.key, this.size = 108, this.onInk = true});

  final double size;
  final bool onInk;

  @override
  State<NearzySplashLogo> createState() => _NearzySplashLogoState();
}

class _NearzySplashLogoState extends State<NearzySplashLogo>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: Motion.slow,
  )..forward();

  late final AnimationController _ping = AnimationController(
    vsync: this,
    duration: Motion.ambient,
  )..repeat();

  @override
  void dispose() {
    _intro.dispose();
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markColor = widget.onInk ? AppColors.paper : AppColors.ink;
    final ringColor = widget.onInk ? AppColors.lime : AppColors.sageDeep;

    return SizedBox(
      width: widget.size * 2.4,
      height: widget.size * 2.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Location ping — the one ambient animation on the splash.
          AnimatedBuilder(
            animation: _ping,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(2, (i) {
                  final t = (_ping.value + i * 0.5) % 1.0;
                  return Opacity(
                    opacity: (1 - t) * 0.35,
                    child: Container(
                      width: widget.size * (1 + t * 1.3),
                      height: widget.size * (1 + t * 1.3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ringColor, width: 1.2),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          // Mark drop-in.
          AnimatedBuilder(
            animation: _intro,
            builder: (context, child) {
              final t = Motion.spring.transform(_intro.value);
              return Opacity(
                opacity: _intro.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -widget.size * 0.35 * (1 - t)),
                  child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
                ),
              );
            },
            child: NearzyMark(size: widget.size, color: markColor),
          ),
        ],
      ),
    );
  }
}
