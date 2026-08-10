import 'package:flutter/material.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onItemSelected,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 8,
      indicatorColor: Theme.of(context).colorScheme.errorContainer,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard_rounded),
          label: 'Spaces',
        ),
        NavigationDestination(
          icon: Icon(Icons.shield_outlined),
          selectedIcon: Icon(Icons.shield_rounded),
          label: 'Moderation',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Users',
        ),
      ],
    );
  }
}
