import 'package:flutter/material.dart';

import '../../../../../../data/models/order.dart';
import '../../../../../../theme/app_colors.dart';
import '../../../../../../theme/app_motion.dart';
import '../../../../../../theme/app_spacing.dart';
import '../../../../../../theme/app_text_styles.dart';
import '../../../../../common/animations/nearzy_page_route.dart';
import '../../../../../common/animations/pressable_scale.dart';
import '../../../orders/view/order_detail_screen.dart';
import '../../../orders/widgets/order_summary_card.dart';

/// Live tracker for the one order the customer actually cares about right
/// now — the most recent one still in flight.
///
/// It sits above the browsing sections because an undelivered order outranks
/// discovery: someone who is waiting on a parcel opens the app to check on
/// it, not to shop again.
class ActiveOrderStrip extends StatelessWidget {
  const ActiveOrderStrip({super.key, required this.order});

  final Order order;

  /// The forward-only customer-visible lifecycle. Cancelled orders never
  /// reach this widget — they're terminal, so they aren't "active".
  static const List<OrderStatus> _pipeline = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  String get _subtitle {
    final count = order.itemCount;
    final unit = count == 1 ? 'item' : 'items';
    final shops = order.shopNames;
    final placed = order.placedAt;
    final when = placed == null
        ? null
        : orderRelativeDate(placed).toLowerCase();

    final origin = shops.length == 1
        ? ' from ${shops.first}'
        : shops.length > 1
            ? ' from ${shops.length} shops'
            : '';
    return when == null
        ? '$count $unit$origin'
        : '$count $unit$origin · $when';
  }

  @override
  Widget build(BuildContext context) {
    final reached = _pipeline.indexOf(order.status);
    // An unknown status still renders — as step one — rather than an
    // out-of-range progress bar.
    final progress = ((reached < 0 ? 0 : reached) + 1) / _pipeline.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        4,
        AppSpacing.gutter,
        4,
      ),
      child: PressableScale(
        onTap: () => context.pushScreen(
          () => OrderDetailScreen(orderId: order.id),
        ),
        scale: 0.985,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            gradient: AppColors.inkGradient,
            borderRadius: AppSpacing.borderRadiusXl,
            boxShadow: AppSpacing.shadowSoft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _LiveDot(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ORDER ${order.status.label.toUpperCase()}',
                      style: AppTextStyles.overline
                          .copyWith(color: AppColors.sage),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Track',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.sage),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.sage),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.orderNumber.isEmpty
                    ? 'Your order is on the way'
                    : order.orderNumber,
                style: AppTextStyles.heading4.copyWith(color: AppColors.paper),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                _subtitle,
                style: AppTextStyles.caption.copyWith(color: AppColors.sage),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              _ProgressTrail(
                progress: progress,
                steps: _pipeline,
                reached: reached < 0 ? 0 : reached,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four labelled stops with a bar that fills to the current one.
class _ProgressTrail extends StatelessWidget {
  const _ProgressTrail({
    required this.progress,
    required this.steps,
    required this.reached,
  });

  final double progress;
  final List<OrderStatus> steps;
  final int reached;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusFull,
          child: SizedBox(
            height: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.inkMuted),
                // Grows on entrance so the bar reads as travel rather than a
                // static gauge.
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: Motion.duration(context, Motion.slow),
                  curve: Motion.emphasis,
                  builder: (context, value, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value.clamp(0.0, 1.0),
                    child: const ColoredBox(color: AppColors.lime),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Text(
                  steps[i].label,
                  textAlign: i == 0
                      ? TextAlign.start
                      : i == steps.length - 1
                          ? TextAlign.end
                          : TextAlign.center,
                  style: AppTextStyles.micro.copyWith(
                    color: i <= reached ? AppColors.paper : AppColors.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The screen's single ambient animation: a slow breath on the status dot,
/// which is what makes the strip read as live rather than a stale snapshot.
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.ambient,
  );

  late final Animation<double> _pulse =
      CurvedAnimation(parent: _controller, curve: Motion.gentle);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion leaves the dot lit and still.
    if (Motion.duration(context, Motion.ambient) == Duration.zero) {
      _controller.stop();
      return;
    }
    if (!_controller.isAnimating) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // A halo that swells and fades, so the dot itself never moves.
              Transform.scale(
                scale: 1 + t,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lime.withValues(alpha: 0.3 * (1 - t)),
                  ),
                  child: const SizedBox.square(dimension: 10),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lime,
                ),
                child: SizedBox.square(dimension: 6),
              ),
            ],
          );
        },
      ),
    );
  }
}
