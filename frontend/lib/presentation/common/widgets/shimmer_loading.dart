import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Consistent shimmer / skeleton loading widgets using standard box layouts
/// (No shrinkwrapping viewports, avoiding any intrinsic measurement issues in Slivers).
class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: child,
    );
  }

  // ── Product grid skeleton (No shrinkWrap Viewport & Overflow-safe) ───
  static Widget productGrid({int count = 4}) {
    final rows = (count / 2).ceil();
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Expanded(
                  child: SizedBox(
                    height: 220,
                    child: _ProductCardSkeleton(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: rowIndex * 2 + 1 < count
                      ? const SizedBox(
                          height: 220,
                          child: _ProductCardSkeleton(),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Horizontal product skeleton ─────────────────────────────────────
  static Widget productRow({int count = 4}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(count, (index) {
          return const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 150,
              height: 220,
              child: _ProductCardSkeleton(),
            ),
          );
        }),
      ),
    );
  }

  // ── Shop grid skeleton (Overflow-safe) ──────────────────────────────
  static Widget shopGrid({int count = 4}) {
    final rows = (count / 2).ceil();
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Expanded(
                  child: SizedBox(
                    height: 180,
                    child: _ShopCardSkeleton(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: rowIndex * 2 + 1 < count
                      ? const SizedBox(
                          height: 180,
                          child: _ShopCardSkeleton(),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Category grid skeleton (Overflow-safe) ──────────────────────────
  static Widget categoryGrid({int count = 6}) {
    final rows = (count / 2).ceil();
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Expanded(
                  child: SizedBox(
                    height: 140,
                    child: _CategorySkeleton(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: rowIndex * 2 + 1 < count
                      ? const SizedBox(
                          height: 140,
                          child: _CategorySkeleton(),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Single line skeleton ────────────────────────────────────────────
  static Widget line({double width = double.infinity, double height = 14}) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: AppSpacing.borderRadiusSm,
        ),
      ),
    );
  }

  // ── Circle skeleton ─────────────────────────────────────────────────
  static Widget circle({double size = 48}) {
    return ShimmerLoading(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.shimmerBase,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopCardSkeleton extends StatelessWidget {
  const _ShopCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
    );
  }
}
