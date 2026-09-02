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
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusFull = 999;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusFull =
      BorderRadius.circular(radiusFull);

  // ── Layout ────────────────────────────────────────────────────────────
  /// Horizontal screen gutter. Every screen hugs this.
  static const double gutter = 20;

  /// Gap between cards in a grid.
  static const double gridGap = 14;

  /// Vertical rhythm between top-level sections.
  static const double sectionGap = 28;

  /// Trailing padding scrollable content needs so its tail clears the
  /// floating bottom nav.
  static const double bottomNavInset = 104;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: gutter);

  // ── Shadows ───────────────────────────────────────────────────────────
  // Tinted toward ink rather than pure black — a neutral-black shadow over a
  // warm paper background reads as grey dirt.
  static const Color _shadowTint = Color(0xFF0F1A15);

  static List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: _shadowTint.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// The default card shadow.
  static List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: _shadowTint.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> shadowMedium = shadowSoft;

  static List<BoxShadow> shadowElevated = [
    BoxShadow(
      color: _shadowTint.withValues(alpha: 0.1),
      blurRadius: 36,
      offset: const Offset(0, 14),
      spreadRadius: -8,
    ),
  ];

  static List<BoxShadow> shadowCard = shadowSoft;

  /// For the floating bottom nav and other ink-coloured floating surfaces.
  static List<BoxShadow> shadowFloating = [
    BoxShadow(
      color: _shadowTint.withValues(alpha: 0.22),
      blurRadius: 28,
      offset: const Offset(0, 10),
      spreadRadius: -6,
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
