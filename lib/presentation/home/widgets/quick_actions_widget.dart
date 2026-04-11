import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Widget hiển thị 4 nút hành động nhanh: Đặt vé, Tư vấn, Xin nghỉ, Lịch sử.
/// Theo design HTML: grid 4 cột, tất cả icon dùng primary color, size 56px.
class QuickActionsWidget extends StatelessWidget {
  final VoidCallback? onBookTicket;
  final VoidCallback? onChatbot;
  final VoidCallback? onLeaveRequest;
  final VoidCallback? onHistory;

  const QuickActionsWidget({
    super.key,
    this.onBookTicket,
    this.onChatbot,
    this.onLeaveRequest,
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
          icon: Icons.confirmation_num_rounded,
          label: 'Đặt vé',
          colorScheme: colorScheme,
          isDark: isDark,
          onTap: onBookTicket ?? () {},
        ),
        _ActionButton(
          icon: Icons.smart_toy_rounded,
          label: 'Tư vấn',
          colorScheme: colorScheme,
          isDark: isDark,
          onTap: onChatbot ?? () {},
        ),
        _ActionButton(
          icon: Icons.event_busy_rounded,
          label: 'Xin nghỉ',
          colorScheme: colorScheme,
          isDark: isDark,
          onTap: onLeaveRequest ?? () {},
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

/// Button đơn trong nhóm hành động nhanh — theo design HTML.
/// Tất cả icon dùng primary color, container có nền primary/10 (light) hoặc darkCard (dark).
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
