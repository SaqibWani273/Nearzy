import 'package:flutter/material.dart';

import '../../../theme/app_motion.dart';

/// Cross-fades between whatever [child] currently is, whenever [state]
/// changes — the app's skeleton-to-content and label-swap transition.
///
/// This exists instead of a bare [AnimatedSwitcher] because that widget keys
/// its entries by the child's own key ([AnimatedSwitcher.defaultTransitionBuilder]
/// stamps `ValueKey(child.key)` onto the transition it builds). Children with
/// no key therefore all share one key, and a key that comes back around — the
/// same skeleton twice, a label returning to a value it held before — repeats
/// one. The switcher drops a single outgoing entry that collides with the
/// incoming one, but two of them fading out at once land in its [Stack]
/// together and throw "Duplicate keys found". Switching faster than [duration]
/// is all it takes.
///
/// A monotonic revision, bumped only when [state] actually changes, keeps
/// every entry distinct while still letting a rebuild carrying the same state
/// update the child in place rather than animating over itself.
class CrossFade extends StatefulWidget {
  const CrossFade({
    super.key,
    required this.state,
    required this.child,
    this.duration = Motion.base,
  });

  /// What [child] is currently showing — a loading flag, an area name, a
  /// record of whatever distinguishes one phase from the next. Compared with
  /// `==`, so records and value objects work; identity-compared objects will
  /// cross-fade on every rebuild.
  final Object? state;

  final Widget child;

  /// Length of the cross-fade. Routed through [Motion.duration], so "reduce
  /// motion" turns it into a cut.
  final Duration duration;

  @override
  State<CrossFade> createState() => _CrossFadeState();
}

class _CrossFadeState extends State<CrossFade> {
  int _revision = 0;

  @override
  void didUpdateWidget(CrossFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) _revision++;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.duration(context, widget.duration),
      child: KeyedSubtree(
        key: ValueKey<int>(_revision),
        child: widget.child,
      ),
    );
  }
}
