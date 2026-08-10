import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onItemSelected,
      backgroundColor: Colors.black.withOpacity(0.5),
      elevation: 0,
      indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: Colors.white70),
          selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined, color: Colors.white70),
          selectedIcon: Icon(Icons.explore_rounded, color: Colors.white),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.mic_none_rounded, color: Colors.white70),
          selectedIcon: Icon(Icons.mic_rounded, color: Colors.white),
          label: 'Spaces',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded, color: Colors.white70),
          selectedIcon: Icon(Icons.person_rounded, color: Colors.white),
          label: 'Profile',
        ),
      ],
    );
  }
}
