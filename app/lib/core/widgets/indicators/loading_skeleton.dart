import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C28) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: const Duration(milliseconds: 1500),
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white60,
        );
  }
}

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LoadingSkeleton(width: 48, height: 48, borderRadius: 24),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(width: 140, height: 16, borderRadius: 4),
                  SizedBox(height: 8),
                  LoadingSkeleton(width: 90, height: 12, borderRadius: 4),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          LoadingSkeleton(
              width: double.infinity, height: 240, borderRadius: 20),
          SizedBox(height: 20),
          LoadingSkeleton(width: 200, height: 16, borderRadius: 4),
        ],
      ),
    );
  }
}
