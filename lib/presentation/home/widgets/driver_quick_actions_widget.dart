import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class DriverQuickActionsWidget extends StatelessWidget {
  final VoidCallback? onScanQR;
  final VoidCallback? onStationList;
  final VoidCallback? onSupport;
  final VoidCallback? onHistory;

  const DriverQuickActionsWidget({
    super.key,
    this.onScanQR,
    this.onStationList,
    this.onSupport,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Quét QR',
          colorScheme: colorScheme,
          isDark: isDark,
          onTap: onScanQR ?? () {},
        ),
        _ActionButton(
          icon: Icons.format_list_numbered_rounded,
          label: 'DS Chuyến',
          colorScheme: colorScheme,
          isDark: isDark,
          onTap: onStationList ?? () {},
        ),
        _ActionButton(
          icon: Icons.support_agent_rounded,
          label: 'Hỗ trợ',
          colorScheme: colorScheme,
          isDark: isDark,
          onTap: onSupport ?? () {},
        ),
        _ActionButton(
          icon: Icons.history_rounded,
          label: 'Lịch sử',
          colorScheme: colorScheme,
          isDark: isDark,
          onTap: onHistory ?? () {},
        ),
      ],
    );
  }
}

/// Button đơn trong nhóm hành động nhanh — theo design hệ thống.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSM),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
