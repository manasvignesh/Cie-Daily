import 'package:flutter/material.dart';

class AppTag extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;

  const AppTag({
    super.key,
    required this.text,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagColor = color ?? theme.colorScheme.primary.withValues(alpha: 0.1);
    final tagTextColor = textColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: tagTextColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
