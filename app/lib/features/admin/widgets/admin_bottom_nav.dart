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
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onItemSelected,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: const Color(0xFFFF5A1F).withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Colors.white54),
              selectedIcon:
                  Icon(Icons.dashboard_rounded, color: Color(0xFFFF5A1F)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined, color: Colors.white54),
              selectedIcon:
                  Icon(Icons.space_dashboard_rounded, color: Color(0xFFFF5A1F)),
              label: 'Spaces',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined, color: Colors.white54),
              selectedIcon:
                  Icon(Icons.shield_rounded, color: Color(0xFFFF5A1F)),
              label: 'Moderation',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded, color: Colors.white54),
              selectedIcon:
                  Icon(Icons.people_rounded, color: Color(0xFFFF5A1F)),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }
}
