import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// The complete Nearzy theme.
///
/// Every Material component is configured against the brand palette so screen
/// code rarely needs an ad-hoc colour override. If you find yourself passing a
/// colour to a widget, check whether it belongs here instead.
final ThemeData nearzyTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.paper,
  canvasColor: AppColors.paper,

  colorScheme: const ColorScheme.light(
    primary: AppColors.ink,
    onPrimary: AppColors.textOnInk,
    primaryContainer: AppColors.sageSurface,
    onPrimaryContainer: AppColors.ink,
    secondary: AppColors.limeDeep,
    onSecondary: AppColors.textOnLime,
    secondaryContainer: AppColors.limeSurface,
    onSecondaryContainer: AppColors.ink,
    surface: AppColors.card,
    onSurface: AppColors.textPrimary,
    surfaceContainerLowest: AppColors.card,
    surfaceContainer: AppColors.paper,
    surfaceContainerHighest: AppColors.paperDim,
    onSurfaceVariant: AppColors.textSecondary,
    error: AppColors.error,
    onError: AppColors.textOnInk,
    errorContainer: AppColors.errorSurface,
    onErrorContainer: AppColors.error,
    outline: AppColors.line,
    outlineVariant: AppColors.line,
  ),

  // ── Typography ──────────────────────────────────────────────────────
  textTheme: GoogleFonts.interTextTheme().copyWith(
    displayLarge: AppTextStyles.display,
    headlineLarge: AppTextStyles.heading1,
    headlineMedium: AppTextStyles.heading2,
    headlineSmall: AppTextStyles.heading3,
    titleLarge: AppTextStyles.sectionTitle,
    titleMedium: AppTextStyles.heading4,
    titleSmall: AppTextStyles.labelLarge,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelSmall,
    labelSmall: AppTextStyles.micro,
  ),

  // ── AppBar ──────────────────────────────────────────────────────────
  appBarTheme: AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    backgroundColor: AppColors.paper,
    foregroundColor: AppColors.textPrimary,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    titleTextStyle: AppTextStyles.heading3,
    iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
  ),

  // ── Cards ───────────────────────────────────────────────────────────
  // Elevation comes from AppSpacing shadows, never from Material elevation —
  // Material's shadow is neutral black and muddies the warm palette.
  cardTheme: CardThemeData(
    elevation: 0,
    color: AppColors.card,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
    margin: EdgeInsets.zero,
  ),

  // ── Buttons ─────────────────────────────────────────────────────────
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.lime,
      disabledBackgroundColor: AppColors.paperDim,
      disabledForegroundColor: AppColors.textTertiary,
      elevation: 0,
      minimumSize: const Size(0, 56),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusFull),
      textStyle: AppTextStyles.buttonText,
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.lime,
      foregroundColor: AppColors.textOnLime,
      minimumSize: const Size(0, 56),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusFull),
      textStyle: AppTextStyles.buttonText,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.ink,
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      side: const BorderSide(color: AppColors.line, width: 1.4),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusFull),
      textStyle: AppTextStyles.buttonText,
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.sageDeep,
      textStyle: AppTextStyles.link,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusFull),
    ),
  ),

  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      minimumSize: const Size(44, 44),
    ),
  ),

  // ── Input fields ────────────────────────────────────────────────────
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusLg,
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusLg,
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusLg,
      borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusLg,
      borderSide: const BorderSide(color: AppColors.error, width: 1.4),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusLg,
      borderSide: const BorderSide(color: AppColors.error, width: 1.6),
    ),
    hintStyle: AppTextStyles.inputHint,
    labelStyle: AppTextStyles.inputLabel,
    floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
    ),
    errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
    prefixIconColor: AppColors.textTertiary,
    suffixIconColor: AppColors.textTertiary,
  ),

  // ── Chips ───────────────────────────────────────────────────────────
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.card,
    selectedColor: AppColors.ink,
    checkmarkColor: AppColors.lime,
    labelStyle: AppTextStyles.labelSmall,
    secondaryLabelStyle:
        AppTextStyles.labelSmall.copyWith(color: AppColors.textOnInk),
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusFull),
    side: const BorderSide(color: AppColors.line),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    showCheckmark: false,
  ),

  // ── Surfaces ────────────────────────────────────────────────────────
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.ink,
    contentTextStyle:
        AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnInk),
    actionTextColor: AppColors.lime,
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
    behavior: SnackBarBehavior.floating,
    insetPadding: const EdgeInsets.all(16),
    elevation: 0,
  ),

  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: AppColors.card,
    surfaceTintColor: Colors.transparent,
    modalBackgroundColor: AppColors.card,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    showDragHandle: true,
    dragHandleColor: AppColors.line,
    dragHandleSize: const Size(44, 4),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.card,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
    titleTextStyle: AppTextStyles.heading3,
    contentTextStyle: AppTextStyles.bodyMedium,
  ),

  dividerTheme: const DividerThemeData(
    color: AppColors.line,
    thickness: 1,
    space: 1,
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.lime,
    foregroundColor: AppColors.textOnLime,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    highlightElevation: 0,
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
  ),

  tabBarTheme: TabBarThemeData(
    labelColor: AppColors.ink,
    unselectedLabelColor: AppColors.textTertiary,
    labelStyle: AppTextStyles.labelLarge,
    unselectedLabelStyle:
        AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w500),
    indicatorColor: AppColors.ink,
    indicatorSize: TabBarIndicatorSize.label,
    dividerHeight: 0,
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.ink,
    linearTrackColor: AppColors.paperDim,
    circularTrackColor: Colors.transparent,
  ),

  sliderTheme: const SliderThemeData(
    activeTrackColor: AppColors.ink,
    inactiveTrackColor: AppColors.paperDim,
    thumbColor: AppColors.ink,
    overlayColor: Color(0x1A0F1A15),
    trackHeight: 4,
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.lime
            : AppColors.card),
    trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.ink
            : AppColors.paperDim),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  ),

  listTileTheme: const ListTileThemeData(
    iconColor: AppColors.textSecondary,
    contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
  ),

  // ── Page transitions ────────────────────────────────────────────────
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _NearzyTransitionBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  ),

  // ── Misc ────────────────────────────────────────────────────────────
  splashFactory: InkSparkle.splashFactory,
  splashColor: const Color(0x140F1A15),
  highlightColor: const Color(0x0A0F1A15),
  visualDensity: VisualDensity.standard,
);

/// Applies the app's shared-axis transition to routes pushed by Material
/// widgets that build their own `MaterialPageRoute` internally.
class _NearzyTransitionBuilder extends PageTransitionsBuilder {
  const _NearzyTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.duration(context, Motion.slow) == Duration.zero) return child;

    final enter = CurvedAnimation(parent: animation, curve: Motion.emphasis);
    return SlideTransition(
      position:
          Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(enter),
      child: FadeTransition(opacity: enter, child: child),
    );
  }
}

/// Legacy alias — kept for backwards compat during migration.
// ignore: non_constant_identifier_names
final ThemeData AppTheme = nearzyTheme;
