import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../data/models/shop_verification.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_motion.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import 'verification_card.dart';

/// Which way the reviewer threw the card.
enum SwipeDecision { approve, reject }

/// A deck of applications judged by throwing the top card left or right.
///
/// `Dismissible` is the wrong primitive here: it expects a list child rather
/// than a z-stacked deck, and gives no way to show the next card settling into
/// place beneath the one being thrown. The pan gesture and fling are driven by
/// an `AnimationController` directly — the same approach `AnimatedMapMixin`
/// already takes for the map camera.
class VerificationCardStack extends StatefulWidget {
  const VerificationCardStack({
    super.key,
    required this.items,
    required this.onDecide,
    this.onOpenDocument,
  });

  final List<ShopVerification> items;

  /// Called once the card has flown off screen. The parent owns the list, so
  /// it decides whether to remove the item or put it back on failure.
  final void Function(ShopVerification, SwipeDecision) onDecide;

  final void Function(VerificationDocument)? onOpenDocument;

  @override
  State<VerificationCardStack> createState() => VerificationCardStackState();
}

class VerificationCardStackState extends State<VerificationCardStack>
    with SingleTickerProviderStateMixin {
  /// Fraction of the card's width it must travel — or be flung past — before
  /// the throw commits. Below this it springs back.
  static const double _commitFraction = 0.28;
  static const double _flingVelocity = 700;

  /// Created in `initState`, not as a lazy `late final`.
  ///
  /// A lazy initializer is never run when the queue is empty — `build` returns
  /// before touching it — and `dispose` would then *construct* a controller on
  /// a deactivated element, where looking up `TickerMode` is unsafe. That is a
  /// real crash for an admin who opens a clear queue and navigates away.
  late final AnimationController _controller;

  Offset _drag = Offset.zero;
  Animation<Offset>? _flight;
  SwipeDecision? _committed;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Motion.base)
      ..addListener(_tick);
  }

  void _tick() {
    final flight = _flight;
    if (flight == null) return;
    setState(() => _drag = flight.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Throws the top card programmatically — used by the explicit
  /// approve/reject buttons, so keyboard and screen-reader users get the same
  /// outcome as a swipe without having to perform one.
  void swipe(SwipeDecision decision) {
    if (_controller.isAnimating || widget.items.isEmpty) return;
    final width = context.size?.width ?? 400;
    _throw(decision, width);
  }

  void _throw(SwipeDecision decision, double width) {
    _committed = decision;
    final endX = decision == SwipeDecision.approve ? width * 1.6 : -width * 1.6;

    _flight = Tween<Offset>(
      begin: _drag,
      end: Offset(endX, _drag.dy + 40),
    ).animate(CurvedAnimation(parent: _controller, curve: Motion.emphasis));

    HapticFeedback.mediumImpact();
    _controller.forward(from: 0).then((_) {
      final item = widget.items.first;
      final outcome = _committed!;
      // Reset before notifying: the parent rebuilds with a shorter list, and a
      // stale offset would make the next card appear mid-throw.
      setState(() {
        _drag = Offset.zero;
        _flight = null;
        _committed = null;
      });
      _controller.value = 0;
      widget.onDecide(item, outcome);
    });
  }

  void _springBack() {
    _flight = Tween<Offset>(begin: _drag, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Motion.spring));
    _controller.forward(from: 0).then((_) {
      if (mounted) setState(() => _flight = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final progress = (_drag.dx / (width * _commitFraction)).clamp(-1.0, 1.0);

        return Stack(
          // Expand rather than size to the card's intrinsic height: the
          // documents are the thing being judged, and letting them claim the
          // full column makes them large enough to actually read.
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            // The next application, settling forward as the top card leaves.
            if (widget.items.length > 1)
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.94 + 0.06 * progress.abs(),
                  child: Opacity(
                    opacity: 0.6 + 0.4 * progress.abs(),
                    child: VerificationCard(verification: widget.items[1]),
                  ),
                ),
              ),

            GestureDetector(
              onPanUpdate: (details) {
                if (_controller.isAnimating) return;
                setState(() => _drag += details.delta);
              },
              onPanEnd: (details) {
                if (_controller.isAnimating) return;
                final velocity = details.velocity.pixelsPerSecond.dx;
                final past = _drag.dx.abs() > width * _commitFraction;
                final flung = velocity.abs() > _flingVelocity;

                if (past || flung) {
                  // A fast flick counts even if the finger never travelled far,
                  // which is how the gesture actually feels in the hand.
                  final dir = (flung ? velocity : _drag.dx) > 0;
                  _throw(
                    dir ? SwipeDecision.approve : SwipeDecision.reject,
                    width,
                  );
                } else {
                  _springBack();
                }
              },
              child: Transform.translate(
                offset: _drag,
                child: Transform.rotate(
                  // Tilts into the throw, capped so it never reads as spinning.
                  angle: (_drag.dx / width) * 0.28,
                  child: Stack(
                    // Also expand: the Transform above passes the outer tight
                    // constraints down, but a loose Stack would hand the card
                    // back its intrinsic height and undo them.
                    fit: StackFit.expand,
                    children: [
                      VerificationCard(
                        verification: widget.items.first,
                        onOpenDocument: widget.onOpenDocument,
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _DecisionWash(progress: progress),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The colour and stamp that grow as the card travels, so the reviewer knows
/// which way they are committing before they let go.
class _DecisionWash extends StatelessWidget {
  const _DecisionWash({required this.progress});

  /// -1 (fully rejecting) to 1 (fully approving).
  final double progress;

  @override
  Widget build(BuildContext context) {
    final magnitude = progress.abs();
    if (magnitude < 0.02) return const SizedBox.shrink();

    final approving = progress > 0;
    final tone = approving ? AppColors.success : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14 * magnitude),
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      child: Align(
        alignment: approving ? Alignment.topLeft : Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Transform.rotate(
            angle: approving ? -0.24 : 0.24,
            child: Opacity(
              opacity: math.min(1, magnitude * 1.4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: tone, width: 3),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Text(
                  approving ? 'APPROVE' : 'REJECT',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: tone,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
