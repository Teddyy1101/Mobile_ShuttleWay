import 'package:flutter/material.dart';

/// Trạng thái giao dịch.
enum TransactionStatus { success, failed, pending }

/// Widget hiển thị 1 item giao dịch trong danh sách lịch sử thanh toán.
/// Giống 100% design HTML reference.
class TransactionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String amount;
  final Color? amountColor;
  final TransactionStatus status;
  final bool isStrikethrough;
  final double opacity;

  const TransactionItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.amountColor,
    required this.status,
    this.isStrikethrough = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C252E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color.lerp(Colors.white, iconColor, 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            // Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: isStrikethrough
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount + Status badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: amountColor ?? _getDefaultAmountColor(isDark),
                    decoration: isStrikethrough
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStatusBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDefaultAmountColor(bool isDark) {
    if (amount.startsWith('+')) return const Color(0xFF22C55E);
    return isDark ? Colors.white : Colors.grey[900]!;
  }

  Widget _buildStatusBadge() {
    final (label, bgColor, textColor) = switch (status) {
      TransactionStatus.success => (
          'Thành công',
          const Color(0xFF22C55E).withValues(alpha: 0.2),
          const Color(0xFF22C55E),
        ),
      TransactionStatus.failed => (
          'Thất bại',
          const Color(0xFFEF4444).withValues(alpha: 0.2),
          const Color(0xFFEF4444),
        ),
      TransactionStatus.pending => (
          'Chờ xử lý',
          const Color(0xFFF59E0B).withValues(alpha: 0.2),
          const Color(0xFFF59E0B),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

