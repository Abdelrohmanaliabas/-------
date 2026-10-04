import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mazikty/core/constants/app_colors.dart';

class CustomShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const CustomShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const CustomShimmer.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surfaceCard.withAlpha(200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? (borderRadius ?? BorderRadius.circular(12))
              : null,
        ),
      ),
    );
  }
}

class ShimmerSongList extends StatelessWidget {
  final int count;

  const ShimmerSongList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Row(
        children: [
          const CustomShimmer(width: 56, height: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CustomShimmer(width: 160, height: 16),
                SizedBox(height: 8),
                CustomShimmer(width: 100, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const CustomShimmer.circular(size: 32),
        ],
      ),
    );
  }
}
