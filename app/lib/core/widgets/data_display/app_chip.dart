import 'package:flutter/material.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onSelected;
  final IconData? icon;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected 
              ? Colors.white 
              : Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      avatar: icon != null 
          ? Icon(
              icon,
              size: 16,
              color: isSelected 
                  ? Colors.white 
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ) 
          : null,
      backgroundColor: isSelected 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: isSelected 
            ? Colors.transparent 
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      onPressed: onSelected,
    );
  }
}
