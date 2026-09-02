import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Named text presets for Nearzy.
///
/// Two families, no more: Plus Jakarta Sans for anything that carries the
/// brand's voice (headings, prices, the wordmark), Inter for everything the
/// user actually reads. Headings run large with tight tracking — a screen
/// title is 28px+, not 20px, which is most of what separates this from a
/// stock Material app.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _display(double size, FontWeight w, Color c, double track) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        color: c,
        letterSpacing: track,
        height: 1.15,
      );

  // ── Brand ─────────────────────────────────────────────────────────────
  static TextStyle brand = _display(26, FontWeight.w800, AppColors.ink, -0.8);

  // ── Display & headings ────────────────────────────────────────────────
  static TextStyle display =
      _display(34, FontWeight.w800, AppColors.textPrimary, -1.0);
  static TextStyle heading1 =
      _display(28, FontWeight.w700, AppColors.textPrimary, -0.8);
  static TextStyle heading2 =
      _display(22, FontWeight.w700, AppColors.textPrimary, -0.5);
  static TextStyle heading3 =
      _display(18, FontWeight.w700, AppColors.textPrimary, -0.3);
  static TextStyle heading4 =
      _display(16, FontWeight.w700, AppColors.textPrimary, -0.2);

  // ── Body ──────────────────────────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.55,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle micro = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.4,
  );

  // ── Labels ────────────────────────────────────────────────────────────
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  /// All-caps section eyebrow, e.g. "NEAR YOU".
  static TextStyle overline = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textTertiary,
    letterSpacing: 1.2,
  );

  // ── Prices ────────────────────────────────────────────────────────────
  // Tabular figures so a column of prices stays aligned as digits change.
  static TextStyle priceLarge = GoogleFonts.plusJakartaSans(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle priceMedium = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle priceSmall = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle priceStrikethrough = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.textTertiary,
  );

  // ── Component-specific ────────────────────────────────────────────────
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textOnInk,
  );

  static TextStyle navLabel = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle badge = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnLime,
    height: 1.1,
  );

  static TextStyle link = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.sageDeep,
  );

  static TextStyle sectionTitle =
      _display(20, FontWeight.w700, AppColors.textPrimary, -0.4);

  static TextStyle sectionSubtitle = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle inputHint = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  static TextStyle inputLabel = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
