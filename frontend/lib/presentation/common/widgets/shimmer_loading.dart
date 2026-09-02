import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Skeleton placeholders.
///
/// Each one mirrors the silhouette of the widget it stands in for — a
/// skeleton whose shape differs from the loaded content produces a visible
/// jump when the data lands, which is worse than no skeleton at all.
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _wrap(child);

  static Widget _wrap(Widget child) => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        period: const Duration(milliseconds: 1400),
        child: child,
      );

  /// Mirrors the 2-column product grid at `mainAxisExtent: 268`.
  static Widget productGrid({int count = 4}) => _wrap(
        _StaticGrid(
          count: count,
          columns: 2,
          itemHeight: 268,
          builder: (_) => const _CardSkeleton(imageFlex: 6, lines: 3),
        ),
      );

  /// Horizontal carousel of product cards.
  static Widget productRow({int count = 4}) {
    return _wrap(
      SizedBox(
        height: 268,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.gridGap),
          itemBuilder: (_, _) => const SizedBox(
            width: 168,
            child: _CardSkeleton(imageFlex: 6, lines: 3),
          ),
        ),
      ),
    );
  }

  /// Mirrors the 2-column shop grid at `mainAxisExtent: 244`.
  static Widget shopGrid({int count = 4}) => _wrap(
        _StaticGrid(
          count: count,
          columns: 2,
          itemHeight: 244,
          builder: (_) => const _CardSkeleton(imageFlex: 5, lines: 2),
        ),
      );

  static Widget categoryGrid({int count = 6}) => _wrap(
        _StaticGrid(
          count: count,
          columns: 3,
          itemHeight: 116,
          builder: (_) => Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: AppColors.shimmerBase,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 10),
              _bar(width: 52, height: 9),
            ],
          ),
        ),
      );

  /// Full-width list of compact rows — cart, orders, search history.
  static Widget listRows({int count = 4, double height = 92}) => _wrap(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Column(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: AppSpacing.borderRadiusLg,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  static Widget line({double width = double.infinity, double height = 14}) =>
      _wrap(_bar(width: width, height: height));

  static Widget circle({double size = 48}) => _wrap(
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.shimmerBase,
            shape: BoxShape.circle,
          ),
        ),
      );

  static Widget _bar({required double width, required double height}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
}

/// Image block over text bars — the shape shared by both card types.
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.imageFlex, required this.lines});

  final int imageFlex;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: imageFlex,
            child: Container(
              width: double.infinity,
              color: AppColors.shimmerBase,
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading._bar(width: double.infinity, height: 11),
                  const SizedBox(height: 7),
                  ShimmerLoading._bar(width: 88, height: 9),
                  if (lines > 2) ...[
                    const Spacer(),
                    ShimmerLoading._bar(width: 62, height: 13),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A fixed grid built from Rows rather than a shrink-wrapped [GridView].
///
/// `infinite_scroll_pagination` puts its first-page indicator inside a
/// `SliverFillRemaining`, which asks its child for intrinsic height — and a
/// shrink-wrapping viewport throws rather than answering. Laying the skeleton
/// out with plain Rows keeps it measurable anywhere.
class _StaticGrid extends StatelessWidget {
  const _StaticGrid({
    required this.count,
    required this.columns,
    required this.itemHeight,
    required this.builder,
  });

  final int count;
  final int columns;
  final double itemHeight;
  final Widget Function(int index) builder;

  @override
  Widget build(BuildContext context) {
    final rows = (count / columns).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < rows; row++) ...[
            if (row > 0) const SizedBox(height: AppSpacing.gridGap),
            SizedBox(
              height: itemHeight,
              child: Row(
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) const SizedBox(width: AppSpacing.gridGap),
                    Expanded(
                      child: row * columns + col < count
                          ? builder(row * columns + col)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
