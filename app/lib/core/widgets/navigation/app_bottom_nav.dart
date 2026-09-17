import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final backgroundColor = AppTheme.glassSurfaceColor(context);
    final borderColor = AppTheme.materialEdgeColor(context);
    final activeColor = AppTheme.accentColor(context);
    final nearGlow = AppTheme.nearGlowColor(context);
    final inactiveColor = AppTheme.secondaryTextColor(context);

    const items = [
      _NavItemData(
          icon: Icons.explore_outlined,
          activeIcon: Icons.explore_rounded,
          label: 'Discover'),
      _NavItemData(
          icon: Icons.play_circle_outline_rounded,
          activeIcon: Icons.play_circle_fill_rounded,
          label: 'Reels'),
      _NavItemData(
          icon: Icons.radio_outlined,
          activeIcon: Icons.radio_rounded,
          label: 'Spaces'),
      _NavItemData(
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          label: 'Connect'),
      _NavItemData(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile'),
    ];

    return SafeArea(
      child: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: isDark ? 0.92 : 0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onItemSelected(index),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppTheme.selectedSurfaceColor(context)
                                  : Colors.transparent,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: nearGlow.withValues(alpha: 0.10),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : const [],
                            ),
                            child: AnimatedScale(
                              scale: isSelected ? 1.06 : 1,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                key: ValueKey('${item.label}_$isSelected'),
                                size: 22,
                                color: isSelected ? activeColor : inactiveColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Breakpoint Marker Dot for Active Tab
                      if (isSelected)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.55, end: 1),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => Transform.scale(
                            scale: value,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: activeColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: nearGlow.withValues(
                                      alpha: 0.20,
                                    ),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: inactiveColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
