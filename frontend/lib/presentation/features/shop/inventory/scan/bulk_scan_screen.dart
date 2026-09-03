import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../../data/models/bulk_stock.dart';
import '../../../../../services/api_service.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/animations/entrance.dart';
import '../../../../common/animations/pressable_scale.dart';

/// Bulk stock intake by camera.
///
/// A shelf sweep produces dozens of barcodes, so scans accumulate into a
/// pending batch and are sent in one transaction rather than one request per
/// beep. Unknown SKUs come back per row instead of failing the batch — a
/// scanner will inevitably catch something the shop has never listed, and
/// losing forty good scans to one stray barcode is the wrong trade.
class BulkScanScreen extends StatefulWidget {
  const BulkScanScreen({super.key});

  @override
  State<BulkScanScreen> createState() => _BulkScanScreenState();
}

class _BulkScanScreenState extends State<BulkScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  );

  /// SKU -> units counted this session, in scan order.
  final Map<String, int> _counts = {};

  /// When each SKU was last accepted. A barcode held in frame fires
  /// continuously, so without this one item would register twenty times.
  final Map<String, DateTime> _lastSeen = {};
  static const Duration _cooldown = Duration(seconds: 2);

  bool _submitting = false;
  BulkStockResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_submitting) return;

    for (final barcode in capture.barcodes) {
      final sku = barcode.rawValue?.trim();
      if (sku == null || sku.isEmpty) continue;

      final now = DateTime.now();
      final seen = _lastSeen[sku];
      if (seen != null && now.difference(seen) < _cooldown) continue;

      _lastSeen[sku] = now;
      setState(() => _counts[sku] = (_counts[sku] ?? 0) + 1);
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _submit() async {
    if (_counts.isEmpty || _submitting) return;
    setState(() => _submitting = true);

    try {
      final result = await ApiService.bulkAdjustStock([
        for (final entry in _counts.entries)
          BulkStockEntry.delta(entry.key, entry.value),
      ]);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _result = result;
        _submitting = false;
        _counts.clear();
        _lastSeen.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('CustomException: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _counts.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _ScannerUnavailable(error: error),
            ),
          ),

          // Scrim so white type stays legible over whatever the camera sees.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.ink.withValues(alpha: 0.75),
                      Colors.transparent,
                      AppColors.ink.withValues(alpha: 0.85),
                    ],
                    stops: const [0, 0.35, 0.72],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  onClose: () => Navigator.of(context).pop(_result != null),
                  onToggleTorch: _controller.toggleTorch,
                ),
                const Spacer(),
                if (_result != null)
                  _ResultSummary(
                    result: _result!,
                    onDismiss: () => setState(() => _result = null),
                  )
                else
                  _Basket(
                    counts: _counts,
                    total: total,
                    submitting: _submitting,
                    onSubmit: _submit,
                    onRemove: (sku) => setState(() {
                      _counts.remove(sku);
                      _lastSeen.remove(sku);
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.onToggleTorch});

  final VoidCallback onClose;
  final VoidCallback onToggleTorch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            tooltip: 'Close scanner',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.ink,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
          const Spacer(),
          Text(
            'Scan to restock',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.paper),
          ),
          const Spacer(),
          IconButton(
            onPressed: onToggleTorch,
            tooltip: 'Toggle torch',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.ink,
            ),
            icon: const Icon(Icons.flashlight_on_rounded),
          ),
        ],
      ),
    );
  }
}

/// What has been scanned but not yet sent.
class _Basket extends StatelessWidget {
  const _Basket({
    required this.counts,
    required this.total,
    required this.submitting,
    required this.onSubmit,
    required this.onRemove,
  });

  final Map<String, int> counts;
  final int total;
  final bool submitting;
  final VoidCallback onSubmit;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (counts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Point the camera at a barcode. Scans collect here and are '
                'applied together.',
                style: AppTextStyles.bodySmall,
              ),
            )
          else ...[
            Text(
              '$total ${total == 1 ? 'unit' : 'units'} across '
              '${counts.length} ${counts.length == 1 ? 'code' : 'codes'}',
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              // Caps the basket so the camera stays usable during a long sweep.
              constraints: const BoxConstraints(maxHeight: 168),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in counts.entries)
                    _BasketRow(
                      sku: entry.key,
                      count: entry.value,
                      onRemove: () => onRemove(entry.key),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: FilledButton(
                onPressed: submitting ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.lime,
                  disabledBackgroundColor: AppColors.line,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                ),
                child: Text(
                  submitting ? 'Applying…' : 'Apply to stock',
                  style: AppTextStyles.buttonText
                      .copyWith(color: AppColors.lime),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BasketRow extends StatelessWidget {
  const _BasketRow({
    required this.sku,
    required this.count,
    required this.onRemove,
  });

  final String sku;
  final int count;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              sku,
              style: AppTextStyles.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.limeSurface,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Text('+$count', style: AppTextStyles.badge),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove $sku from this batch',
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// What landed, and what needs a human. Shown in place of the basket so the
/// unmatched codes cannot be scrolled past unnoticed.
class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.result, required this.onDismiss});

  final BulkStockResult result;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final review = result.needsReview;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${result.applied} '
                '${result.applied == 1 ? 'product' : 'products'} updated',
                style: AppTextStyles.labelLarge,
              ),
            ],
          ),
          if (review.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${review.length} not recognised',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.warning),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'These barcodes match no SKU in your inventory. Add them as '
              'products first, then scan again.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final row in review)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        row.sku.isEmpty ? '(blank code)' : row.sku,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: PressableScale(
              onTap: onDismiss,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paperDim,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  'Scan more',
                  // buttonText is textOnInk — near-white, and this button is
                  // on a light surface.
                  style: AppTextStyles.buttonText
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animateEntrance();
  }
}

class _ScannerUnavailable extends StatelessWidget {
  const _ScannerUnavailable({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: AppColors.ink,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 40,
                color: AppColors.sage,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                denied ? 'Camera access is off' : 'Camera unavailable',
                style: AppTextStyles.heading4.copyWith(color: AppColors.paper),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                denied
                    ? 'Allow camera access in Settings to scan barcodes.'
                    : 'This device could not start the camera.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.sage),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
