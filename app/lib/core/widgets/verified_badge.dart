import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry padding;

  const VerifiedBadge({
    super.key,
    this.size = 16.0,
    this.padding = const EdgeInsets.only(left: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Icon(
        Icons.verified,
        color: Colors.blueAccent,
        size: size,
      ),
    );
  }
}
