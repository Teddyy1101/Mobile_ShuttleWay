import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Trang chủ, Bản đồ, Lịch, Cá nhân.
class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppConstants.bottomNavHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Trang chủ',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
                colorScheme: colorScheme,
              ),
              _NavItem(
                icon: Icons.map_rounded,
                label: 'Bản đồ',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
                colorScheme: colorScheme,
              ),
              _NavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Lịch',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                colorScheme: colorScheme,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Cá nhân',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item trong bottom navigation bar.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppConstants.bottomNavItemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppConstants.iconSizeMD,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: AppConstants.paddingXS),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
