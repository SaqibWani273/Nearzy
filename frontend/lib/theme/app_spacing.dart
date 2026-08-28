import 'package:flutter/material.dart';

/// Consistent spacing, border radius, and shadow tokens.
class AppSpacing {
  AppSpacing._();

  // ── Spacing scale ─────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;

  // ── Padding presets ───────────────────────────────────────────────────
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: base, vertical: sm);
  static const EdgeInsets cardPadding = EdgeInsets.all(base);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md);
  static const EdgeInsets sectionPadding =
      EdgeInsets.symmetric(horizontal: base, vertical: lg);
  static const EdgeInsets inputPadding =
      EdgeInsets.symmetric(horizontal: base, vertical: md);
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: xs);

  // ── Border radius ─────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 100;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusFull =
      BorderRadius.circular(radiusFull);

  // ── Shadows ───────────────────────────────────────────────────────────
  static List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowElevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ── Animation durations ───────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 450);
  static const Duration durationPage = Duration(milliseconds: 350);

  // ── Animation curves ──────────────────────────────────────────────────
  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveSnap = Curves.easeOutBack;
  static const Curve curveBounce = Curves.elasticOut;
}
