import 'package:flutter/material.dart';

/// Nearzy brand color palette.
///
/// Deep navy conveys trust & premium quality.
/// Warm orange conveys energy & calls-to-action.
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A1B4B);
  static const Color primaryLight = Color(0xFF2E3192);
  static const Color primarySoft = Color(0xFF4A4CBF);
  static const Color primarySurface = Color(0xFFEEEFF8);

  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFFAD60);
  static const Color accentSurface = Color(0xFFFFF3EB);

  // ── Neutrals ──────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF8F9FC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F6FA);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);
  static const Color inputFill = Color(0xFFF3F4F6);

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1B2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Semantic ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0xFFEFF6FF);

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFFF8F65)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F9FC), Color(0xFFFFFFFF)],
  );

  // ── Shimmer ───────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF3F4F6);

  // ── Overlay ───────────────────────────────────────────────────────────
  static Color scrim = Colors.black.withValues(alpha: 0.4);
  static Color overlay = Colors.black.withValues(alpha: 0.06);
}
