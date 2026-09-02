import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';

/// The app's only network image widget.
///
/// Caches to disk, shimmers while loading, and falls back to a styled tile
/// rather than Flutter's broken-image glyph — a marketplace full of
/// user-uploaded URLs will always have some that 404, and those should still
/// look deliberate.
class NearzyNetworkImage extends StatelessWidget {
  const NearzyNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.semanticLabel,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final src = url?.trim();
    if (src == null || src.isEmpty || !src.startsWith('http')) {
      return _Fallback(
        width: width,
        height: height,
        icon: fallbackIcon,
      );
    }

    return Semantics(
      label: semanticLabel,
      image: true,
      child: CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: Motion.base,
        fadeInCurve: Motion.easeOut,
        placeholder: (_, _) => _Skeleton(width: width, height: height),
        errorWidget: (_, _, _) =>
            _Fallback(width: width, height: height, icon: fallbackIcon),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        color: AppColors.shimmerBase,
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({this.width, this.height, required this.icon});

  final double? width;
  final double? height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.paperDim,
      alignment: Alignment.center,
      child: Icon(
        icon,
        // Scale the glyph to the tile so a 40px avatar and a 300px hero both
        // look intentional.
        size: _iconSize,
        color: AppColors.sage,
      ),
    );
  }

  double get _iconSize {
    final shortest = [width, height].whereType<double>().fold<double?>(
          null,
          (acc, v) => acc == null ? v : (v < acc ? v : acc),
        );
    if (shortest == null) return 28;
    return (shortest * 0.34).clamp(14.0, 48.0);
  }
}
