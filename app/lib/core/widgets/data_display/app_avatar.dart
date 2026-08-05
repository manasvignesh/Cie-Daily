import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImageProvider(imageUrl!)
          : null,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }
}
