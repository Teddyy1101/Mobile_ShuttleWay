import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Widget cho phép chọn vai trò: Phụ huynh hoặc Học sinh.
/// Hiển thị 2 chip card nằm ngang với icon và label tương ứng.
class RoleSelectorWidget extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const RoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bạn là',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSM),
        Row(
          children: [
            Expanded(
              child: _RoleChip(
                icon: Icons.family_restroom,
                label: 'Phụ huynh',
                value: 'PARENT',
                isSelected: selectedRole == 'PARENT',
                onTap: () => onRoleChanged('PARENT'),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMD),
            Expanded(
              child: _RoleChip(
                icon: Icons.school_outlined,
                label: 'Học sinh',
                value: 'STUDENT',
                isSelected: selectedRole == 'STUDENT',
                onTap: () => onRoleChanged('STUDENT'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Chip card cho một vai trò.
class _RoleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: AppConstants.buttonHeight,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withAlpha(26)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withAlpha(51),
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withAlpha(153),
              size: AppConstants.iconSizeMD,
            ),
            const SizedBox(width: AppConstants.paddingSM),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
