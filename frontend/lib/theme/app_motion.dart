import 'package:flutter/material.dart';

/// The Nearzy motion language.
///
/// Four durations, four curves. Screen code picks from these rather than
/// inventing timings, which is what keeps a fifteen-screen app feeling like
/// one product instead of fifteen.
class Motion {
  Motion._();

  // ── Durations ─────────────────────────────────────────────────────────
  /// Taps, toggles, press-down scale. Below perceptual threshold.
  static const Duration micro = Duration(milliseconds: 120);

  /// Chips, badges, small state flips.
  static const Duration quick = Duration(milliseconds: 220);

  /// The default: entrances, sheets, cross-fades.
  static const Duration base = Duration(milliseconds: 340);

  /// Page transitions, hero flights, expensive reveals.
  static const Duration slow = Duration(milliseconds: 520);

  /// Looping decorative motion. Max one per screen.
  static const Duration ambient = Duration(milliseconds: 2600);

  /// Gap between consecutive items in a staggered list.
  static const Duration stagger = Duration(milliseconds: 45);

  /// Beyond this index items enter together, so a long list never makes the
  /// user wait for its tail.
  static const int maxStaggerIndex = 10;

  // ── Curves ────────────────────────────────────────────────────────────
  /// Anything entering the screen.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Things that should feel physical: badges, FABs, selection, map pins.
  static const Curve spring = Curves.easeOutBack;

  /// Page and sheet transitions — a long, decisive settle.
  static const Curve emphasis = Curves.easeOutQuint;

  /// Looping ambient motion, which must never have a hard edge.
  static const Curve gentle = Curves.easeInOutSine;

  /// Collapsing / exiting content.
  static const Curve exit = Curves.easeInCubic;

  /// Honours the platform "reduce motion" setting.
  ///
  /// Custom animation code should route its durations through this so an
  /// accessibility preference actually reaches the whole app.
  static Duration duration(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : d;

  /// Delay before item [index] in a staggered sequence enters.
  static Duration staggerDelay(int index) =>
      stagger * (index.clamp(0, maxStaggerIndex));
}
