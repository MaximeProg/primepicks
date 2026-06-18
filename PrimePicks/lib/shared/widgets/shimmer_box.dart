import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  const ShimmerBox.wide({super.key, required this.height, this.radius = 8})
      : width = double.infinity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base   = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final high   = isDark ? AppColors.borderDark : AppColors.border;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: high,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ShimmerCouponCard extends StatelessWidget {
  const ShimmerCouponCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 64, height: 22, radius: 6),
              ShimmerBox(width: 64, height: 22, radius: 6),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerBox.wide(height: 18, radius: 4),
          const SizedBox(height: 6),
          ShimmerBox(width: 180, height: 14, radius: 4),
          const SizedBox(height: 12),
          Row(children: [
            ShimmerBox(width: 60, height: 14, radius: 4),
            const SizedBox(width: 16),
            ShimmerBox(width: 80, height: 14, radius: 4),
          ]),
        ],
      ),
    );
  }
}
