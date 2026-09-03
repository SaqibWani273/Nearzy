import 'package:flutter/material.dart';

import '../../../../data/models/shop_verification.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/widgets/nearzy_network_image.dart';
import '../../../common/widgets/shimmer_loading.dart';
import 'widgets/verification_card_stack.dart';

/// The admin's verification queue, worked by swiping.
///
/// Replaces a screen that rendered a hardcoded "no pending verifications"
/// regardless of the queue, because the endpoints behind it had never been
/// routed. Right approves, left rejects, and every decision is undoable for a
/// few seconds — an accidental fling that permanently rejects a real business
/// is the obvious failure mode of this interaction, so it is not permanent.
class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  final _stackKey = GlobalKey<VerificationCardStackState>();

  List<ShopVerification>? _queue;
  Object? _error;
  bool _loading = true;

  /// Decisions swiped but not yet sent. Held for [_undoWindow] so the reviewer
  /// can take one back; flushed to the server when the window closes.
  final List<_PendingDecision> _pending = [];

  static const Duration _undoWindow = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.fetchShopVerifications();
      if (!mounted) return;
      setState(() {
        _queue = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _onDecide(ShopVerification item, SwipeDecision decision) {
    final pending = _PendingDecision(item: item, decision: decision);
    setState(() {
      _queue = [...?_queue]..removeWhere((v) => v.shopId == item.shopId);
      _pending.add(pending);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: _undoWindow,
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.base),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          content: Text(
            decision == SwipeDecision.approve
                ? '${item.shopName} approved'
                : '${item.shopName} rejected',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.paper),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.lime,
            onPressed: () => _undo(pending),
          ),
        ),
      );

    // Commit once the undo window has closed. Tied to a timer rather than the
    // snackbar's own dismissal so a second swipe — which replaces the
    // snackbar — does not silently cancel the first decision.
    Future.delayed(_undoWindow, () => _commit(pending));
  }

  void _undo(_PendingDecision pending) {
    if (pending.settled) return;
    pending.settled = true;
    setState(() {
      _pending.remove(pending);
      // Back to the front: it is still the oldest thing in the queue.
      _queue = [pending.item, ...?_queue];
    });
  }

  Future<void> _commit(_PendingDecision pending) async {
    if (pending.settled) return;
    pending.settled = true;

    try {
      await ApiService.decideShopVerification(
        pending.item.shopId,
        pending.decision == SwipeDecision.approve ? 'APPROVED' : 'REJECTED',
      );
      if (mounted) setState(() => _pending.remove(pending));
    } catch (_) {
      if (!mounted) return;
      // The decision never landed, so the application goes back in the queue
      // rather than vanishing on an optimistic update that failed.
      setState(() {
        _pending.remove(pending);
        _queue = [pending.item, ...?_queue];
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text("Couldn't save that decision — ${pending.item.shopName} is back in the queue."),
          ),
        );
    }
  }

  void _openDocument(VerificationDocument document) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.9),
      builder: (context) => _DocumentViewer(document: document),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const _QueueSkeleton();
    if (_error != null) return _QueueError(onRetry: _load);

    final queue = _queue ?? const <ShopVerification>[];
    if (queue.isEmpty) return _QueueEmpty(onRefresh: _load);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.base,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verification', style: AppTextStyles.heading1),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${queue.length} waiting · oldest first',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                tooltip: 'Refresh queue',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
            ),
            child: VerificationCardStack(
              key: _stackKey,
              items: queue,
              onDecide: _onDecide,
              onOpenDocument: _openDocument,
            ),
          ),
        ),
        _DecisionBar(
          onReject: () => _stackKey.currentState?.swipe(SwipeDecision.reject),
          onApprove: () => _stackKey.currentState?.swipe(SwipeDecision.approve),
        ),
      ],
    );
  }
}

/// A swipe waiting out its undo window.
class _PendingDecision {
  _PendingDecision({required this.item, required this.decision});

  final ShopVerification item;
  final SwipeDecision decision;

  /// Set once either committed or undone, so the delayed commit and the undo
  /// button cannot both act on the same decision.
  bool settled = false;
}

/// Explicit buttons alongside the gesture.
///
/// Not decoration: a swipe is unreachable by keyboard or switch control, and a
/// destructive action should never be gesture-only.
class _DecisionBar extends StatelessWidget {
  const _DecisionBar({required this.onReject, required this.onApprove});

  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Not `bottomNavInset`: that reserves room for content scrolling under
      // the floating nav, but this screen sits inside a shell whose body
      // already stops above it. Using it here would double-count and leave a
      // band of dead space under the buttons.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        AppSpacing.xl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundAction(
            icon: Icons.close_rounded,
            tone: AppColors.error,
            surface: AppColors.errorSurface,
            semanticLabel: 'Reject this application',
            onTap: onReject,
          ),
          const SizedBox(width: AppSpacing.xxl),
          _RoundAction(
            icon: Icons.check_rounded,
            tone: AppColors.success,
            surface: AppColors.successSurface,
            semanticLabel: 'Approve this application',
            onTap: onApprove,
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.tone,
    required this.surface,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color tone;
  final Color surface;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: PressableScale(
        onTap: onTap,
        scale: 0.92,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: surface,
            shape: BoxShape.circle,
            border: Border.all(color: tone.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Icon(icon, size: 28, color: tone),
        ),
      ),
    );
  }
}

/// Full-screen look at one document. Reviewing a PAN card in a half-width pane
/// is not really reviewing it.
class _DocumentViewer extends StatelessWidget {
  const _DocumentViewer({required this.document});

  final VerificationDocument document;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: NearzyNetworkImage(
                  url: document.url,
                  fit: BoxFit.contain,
                  fallbackIcon: Icons.broken_image_outlined,
                  semanticLabel: document.label,
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.base,
            right: AppSpacing.base,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.ink,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
          Positioned(
            bottom: AppSpacing.xl,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(document.label, style: AppTextStyles.labelMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueEmpty extends StatelessWidget {
  const _QueueEmpty({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line, width: 1.5),
              ),
              child: const Icon(
                Icons.verified_outlined,
                size: 36,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text('Queue clear', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Every application has been reviewed.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.base),
            TextButton(
              onPressed: onRefresh,
              child: Text('Check again', style: AppTextStyles.link),
            ),
          ],
        ),
      ),
    ).animateEntrance();
  }
}

class _QueueSkeleton extends StatelessWidget {
  const _QueueSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          ShimmerLoading.line(width: 180, height: 28),
          const SizedBox(height: AppSpacing.sm),
          ShimmerLoading.line(width: 120, height: 12),
          const SizedBox(height: AppSpacing.xl),
          Expanded(child: ShimmerLoading.listRows(count: 1, height: 420)),
        ],
      ),
    );
  }
}

class _QueueError extends StatelessWidget {
  const _QueueError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text("Couldn't load the queue", style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check your connection and try again.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.base),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry', style: AppTextStyles.link),
            ),
          ],
        ),
      ),
    );
  }
}
