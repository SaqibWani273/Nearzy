import 'package:flutter/material.dart';

import '../../../theme/app_motion.dart';

/// Shared-axis page transition: the incoming screen slides a short distance
/// and fades while the outgoing one recedes slightly.
///
/// Use this instead of `MaterialPageRoute` for in-app navigation so pushes
/// feel like one continuous surface rather than a stack of platform cards.
class NearzyPageRoute<T> extends PageRouteBuilder<T> {
  NearzyPageRoute({
    required this.builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: Motion.slow,
          reverseTransitionDuration: Motion.base,
          opaque: true,
        );

  final WidgetBuilder builder;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.duration(context, Motion.slow) == Duration.zero) return child;

    final enter = CurvedAnimation(parent: animation, curve: Motion.emphasis);
    final exit =
        CurvedAnimation(parent: secondaryAnimation, curve: Motion.emphasis);

    return AnimatedBuilder(
      animation: Listenable.merge([enter, exit]),
      builder: (context, inner) {
        return Transform.translate(
          // Incoming slides in from the right; the page underneath drifts
          // left by a third as much, which reads as depth.
          offset: Offset(24 * (1 - enter.value) - 12 * exit.value, 0),
          child: Opacity(
            opacity: enter.value.clamp(0.0, 1.0) * (1 - 0.4 * exit.value),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }
}

/// Vertical sheet-style push, for full-screen modals such as the map picker.
class NearzyModalRoute<T> extends PageRouteBuilder<T> {
  NearzyModalRoute({required this.builder, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: Motion.slow,
          reverseTransitionDuration: Motion.base,
          fullscreenDialog: true,
        );

  final WidgetBuilder builder;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.duration(context, Motion.slow) == Duration.zero) return child;

    final curved = CurvedAnimation(parent: animation, curve: Motion.emphasis);
    return SlideTransition(
      position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
          .animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}

extension NearzyNavigation on BuildContext {
  /// `context.pushScreen(() => const FooScreen())`
  Future<T?> pushScreen<T>(Widget Function() builder) =>
      Navigator.of(this).push<T>(NearzyPageRoute<T>(builder: (_) => builder()));

  Future<T?> pushModal<T>(Widget Function() builder) =>
      Navigator.of(this).push<T>(NearzyModalRoute<T>(builder: (_) => builder()));
}
