import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// The complete Nearzy theme.
///
/// Every Material component is configured to use the brand palette so that
/// ad-hoc color overrides are rarely needed in screen code.
final ThemeData nearzyTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.surface,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    primaryContainer: AppColors.primarySurface,
    secondary: AppColors.accent,
    secondaryContainer: AppColors.accentSurface,
    surface: AppColors.card,
    error: AppColors.error,
    errorContainer: AppColors.errorSurface,
    onPrimary: AppColors.textOnPrimary,
    onSecondary: AppColors.textOnAccent,
    onSurface: AppColors.textPrimary,
    onError: AppColors.textOnPrimary,
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
  ),

  // ── Typography ──────────────────────────────────────────────────────
  textTheme: GoogleFonts.interTextTheme().copyWith(
    headlineLarge: GoogleFonts.dmSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.dmSans(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.dmSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.textTertiary,
      letterSpacing: 0.5,
    ),
  ),

  // ── AppBar ──────────────────────────────────────────────────────────
  appBarTheme: AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0.5,
    centerTitle: false,
    backgroundColor: AppColors.card,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    titleTextStyle: GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary,
      size: 24,
    ),
  ),

  // ── Bottom Navigation ───────────────────────────────────────────────
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    backgroundColor: AppColors.card,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textTertiary,
    selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
    elevation: 8,
    showUnselectedLabels: true,
  ),

  // ── Cards ───────────────────────────────────────────────────────────
  cardTheme: CardThemeData(
    elevation: 0,
    color: AppColors.card,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMd,
    ),
    margin: EdgeInsets.zero,
  ),

  // ── Elevated Buttons ────────────────────────────────────────────────
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  ),

  // ── Outlined Buttons ────────────────────────────────────────────────
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      side: const BorderSide(color: AppColors.border, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  ),

  // ── Text Buttons ────────────────────────────────────────────────────
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.accent,
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  // ── Input Fields ────────────────────────────────────────────────────
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    hintStyle: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.textTertiary,
    ),
    labelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    errorStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.error,
    ),
    prefixIconColor: AppColors.textSecondary,
    suffixIconColor: AppColors.textSecondary,
  ),

  // ── Chips ───────────────────────────────────────────────────────────
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.primarySurface,
    selectedColor: AppColors.primary,
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.primary,
    ),
    secondaryLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textOnPrimary,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusSm,
    ),
    side: BorderSide.none,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  ),

  // ── SnackBar ────────────────────────────────────────────────────────
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.textPrimary,
    contentTextStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textOnPrimary,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMd,
    ),
    behavior: SnackBarBehavior.floating,
    insetPadding: const EdgeInsets.all(16),
  ),

  // ── Bottom Sheet ────────────────────────────────────────────────────
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: AppColors.card,
    surfaceTintColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    showDragHandle: true,
    dragHandleColor: AppColors.divider,
  ),

  // ── Dialog ──────────────────────────────────────────────────────────
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.card,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusLg,
    ),
    titleTextStyle: GoogleFonts.dmSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  ),

  // ── Divider ─────────────────────────────────────────────────────────
  dividerTheme: const DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 0,
  ),

  // ── Floating Action Button ──────────────────────────────────────────
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.textOnAccent,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusLg,
    ),
  ),

  // ── Tab Bar ─────────────────────────────────────────────────────────
  tabBarTheme: TabBarThemeData(
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.textTertiary,
    labelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    indicatorColor: AppColors.primary,
    indicatorSize: TabBarIndicatorSize.label,
    dividerHeight: 0,
  ),

  // ── Page transitions ────────────────────────────────────────────────
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),

  // ── Misc ────────────────────────────────────────────────────────────
  splashColor: AppColors.primary.withValues(alpha: 0.08),
  highlightColor: AppColors.primary.withValues(alpha: 0.04),
  visualDensity: VisualDensity.standard,
);

/// Legacy alias — kept for backwards compat during migration.
// ignore: non_constant_identifier_names
final ThemeData AppTheme = nearzyTheme;
