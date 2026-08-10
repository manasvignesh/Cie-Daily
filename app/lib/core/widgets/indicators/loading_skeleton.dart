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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: const Duration(seconds: 2), color: Colors.white24);
  }
}

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LoadingSkeleton(width: 48, height: 48, borderRadius: 24),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(width: 120, height: 16),
                  SizedBox(height: 8),
                  LoadingSkeleton(width: 80, height: 12),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 200, borderRadius: 16),
          SizedBox(height: 16),
          LoadingSkeleton(width: 200, height: 16),
        ],
      ),
    );
  }
}
