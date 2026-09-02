import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_motion.dart';

/// Fades and lifts its child into place once, on first build.
///
/// This is the app's signature entrance. Give list/grid children their index
/// and they cascade; give a one-off widget no index and it simply fades up.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 16,
    this.duration = Motion.base,
    this.delay = Duration.zero,
    this.curve = Motion.easeOut,
    this.horizontal = false,
  });

  final Widget child;

  /// Position in a staggered sequence. Ignored past [Motion.maxStaggerIndex].
  final int index;

  /// Distance travelled, in logical pixels.
  final double offset;

  final Duration duration;

  /// Added on top of the index-derived stagger.
  final Duration delay;

  final Curve curve;

  /// Slide in from the trailing edge instead of from below — for horizontal
  /// carousels, where a vertical lift reads as a glitch.
  final bool horizontal;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// Held so it can be cancelled: a bare `Future.delayed` keeps running after
  /// dispose, which leaks a pending timer and trips widget tests.
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    final delay = Motion.staggerDelay(widget.index) + widget.delay;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(delay, _controller.forward);
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A reduced-motion preference skips straight to the resting state.
    if (Motion.duration(context, widget.duration) == Duration.zero) {
      return widget.child;
    }

    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final remaining = 1 - curved.value;
        return Opacity(
          // Clamped because `spring` overshoots past 1.
          opacity: curved.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: widget.horizontal
                ? Offset(widget.offset * remaining, 0)
                : Offset(0, widget.offset * remaining),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

extension EntranceX on Widget {
  /// `child.animateEntrance(index: i)` — the shorthand used across screens.
  Widget animateEntrance({
    int index = 0,
    double offset = 16,
    Duration duration = Motion.base,
    Duration delay = Duration.zero,
    Curve curve = Motion.easeOut,
    bool horizontal = false,
  }) =>
      Entrance(
        index: index,
        offset: offset,
        duration: duration,
        delay: delay,
        curve: curve,
        horizontal: horizontal,
        child: this,
      );
}
