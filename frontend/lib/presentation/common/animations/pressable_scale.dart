import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_motion.dart';

/// Wraps a tappable surface so it dips under the finger.
///
/// Every card, tile and custom button in the app uses this — the tactile
/// press is what separates the revamped UI from a stack of `InkWell`s.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptics = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// How far down to dip. Large surfaces want a subtler dip than small ones.
  final double scale;

  /// Fires a light impact on tap. Turn off for high-frequency controls such
  /// as a quantity stepper being held down.
  final bool haptics;

  final HitTestBehavior behavior;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    if (widget.haptics) HapticFeedback.lightImpact();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled ? _handleTap : null,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptics) HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: Motion.duration(context, Motion.micro),
        curve: Motion.easeOut,
        child: widget.child,
      ),
    );
  }
}
