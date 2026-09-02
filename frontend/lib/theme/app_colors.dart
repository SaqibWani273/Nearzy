import 'package:flutter/material.dart';

/// Nearzy brand palette — "Local Premium".
///
/// Near-black ink and warm paper carry almost the whole interface; a single
/// vivid lime accent marks the one thing worth acting on. Sage fills the
/// decorative middle ground (map polygons, hairlines on dark, tinted chips).
///
/// Screen code must never hardcode a hex — pull from here so a palette change
/// stays a one-file change.
class AppColors {
  AppColors._();

  // ── Ink (the dark end) ────────────────────────────────────────────────
  static const Color ink = Color(0xFF0F1A15);
  static const Color inkSoft = Color(0xFF1B2A23);
  static const Color inkMuted = Color(0xFF3A4A42);

  // ── Lime (the one accent) ─────────────────────────────────────────────
  static const Color lime = Color(0xFFC9F24E);
  static const Color limeDeep = Color(0xFFA8D62F);
  static const Color limeSurface = Color(0xFFEEF9D2);

  // ── Sage (decorative middle) ──────────────────────────────────────────
  static const Color sage = Color(0xFF8FA396);
  static const Color sageDeep = Color(0xFF4C6357);
  static const Color sageSurface = Color(0xFFE4EBE4);

  // ── Paper (the light end) ─────────────────────────────────────────────
  static const Color paper = Color(0xFFF7F6F1);
  static const Color paperDim = Color(0xFFEFEDE5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE6E4DC);

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F1A15);
  static const Color textSecondary = Color(0xFF5D6B63);
  static const Color textTertiary = Color(0xFF94A19A);
  static const Color textOnInk = Color(0xFFF7F6F1);
  static const Color textOnLime = Color(0xFF0F1A15);

  // ── Semantic ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E9E6B);
  static const Color successSurface = Color(0xFFE3F5EC);
  static const Color warning = Color(0xFFE0A03C);
  static const Color warningSurface = Color(0xFFFBF1DF);
  static const Color error = Color(0xFFD5533D);
  static const Color errorSurface = Color(0xFFFBEAE7);
  static const Color info = Color(0xFF3C7D8C);
  static const Color infoSurface = Color(0xFFE6F1F3);

  // ── Gradients — only these two exist. Do not invent more. ─────────────
  static const LinearGradient inkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [inkSoft, ink],
  );

  static const LinearGradient limeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lime, limeDeep],
  );

  /// Fades an image's lower half into ink so overlaid text stays legible.
  static const LinearGradient imageScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000F1A15), Color(0x140F1A15), Color(0xCC0F1A15)],
    stops: [0.35, 0.6, 1.0],
  );

  // ── Shimmer ───────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFEAE8E0);
  static const Color shimmerHighlight = Color(0xFFF7F6F1);

  // ── Overlay ───────────────────────────────────────────────────────────
  static Color scrim = ink.withValues(alpha: 0.45);
  static Color overlay = ink.withValues(alpha: 0.06);

  // ── Legacy aliases ────────────────────────────────────────────────────
  // Kept so screens still on the old token names inherit the new palette
  // instead of breaking. Prefer the semantic names above in new code.
  static const Color primary = ink;
  static const Color primaryLight = inkSoft;
  static const Color primarySoft = sageDeep;
  static const Color primarySurface = sageSurface;
  static const Color accent = limeDeep;
  static const Color accentLight = lime;
  static const Color accentSurface = limeSurface;
  static const Color surface = paper;
  static const Color background = paperDim;
  static const Color divider = line;
  static const Color border = line;
  static const Color inputFill = paperDim;
  static const Color textOnPrimary = textOnInk;
  static const Color textOnAccent = textOnLime;
  static const LinearGradient primaryGradient = inkGradient;
  static const LinearGradient accentGradient = limeGradient;
  static const LinearGradient warmGradient = limeGradient;
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [paper, card],
  );
}
