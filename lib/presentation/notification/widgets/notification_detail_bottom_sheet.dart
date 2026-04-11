import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/notification_model.dart';

class NotificationDetailBottomSheet extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onViewTicket;

  const NotificationDetailBottomSheet({
    super.key,
    required this.notification,
    this.onViewTicket,
  });

  /// Hiển thị bottom sheet từ bất kỳ context nào.
  static void show(
    BuildContext context,
    NotificationModel notification, {
    VoidCallback? onViewTicket,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C252E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotificationDetailBottomSheet(
        notification: notification,
        onViewTicket: onViewTicket,
      ),
    );
  }

  /// Kiểm tra xem thông báo có liên quan đến đặt vé không.
  bool get _isTicketNotification {
    final lower = notification.title.toLowerCase();
    return lower.contains('đặt vé') || lower.contains('thanh toán');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final category = _getCategory(notification.title);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon lớn + badge trạng thái
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    size: 32,
                    color: category.color,
                  ),
                ),
                // Badge đã đọc / chưa đọc
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? (isDark ? Colors.grey[700] : Colors.grey[300])
                          : colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1C252E) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      notification.isRead
                          ? Icons.done_rounded
                          : Icons.circle,
                      size: notification.isRead ? 12 : 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tiêu đề
            Text(
              notification.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Trạng thái + thời gian
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(  
                    color: notification.isRead
                        ? (isDark
                            ? Colors.grey[800]
                            : Colors.grey[100])
                        : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    notification.isRead ? 'Đã đọc' : 'Chưa đọc',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: notification.isRead
                          ? (isDark ? Colors.grey[400] : Colors.grey[500])
                          : colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatFullDateTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Divider
            Divider(
              height: 1,
              thickness: 0.5,
              color: isDark
                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                  : Colors.grey[200],
            ),
            const SizedBox(height: 20),

            // Nội dung thông báo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[900]!.withValues(alpha: 0.3)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFF3F4F6),
                ),
              ),
              child: Text(
                notification.body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nút "Xem vé" (chỉ hiện cho thông báo đặt vé)
            if (_isTicketNotification && onViewTicket != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onViewTicket!();
                    },
                    icon: const Icon(
                      Icons.confirmation_number_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'Xem vé',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMD),
                      ),
                    ),
                  ),
                ),
              ),

            // Nút đóng
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMD),
                    side: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                ),
                child: const Text(
                  'Đóng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format đầy đủ ngày giờ (chuyển UTC → giờ địa phương).
  String _formatFullDateTime(DateTime dateTime) {
    return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime.toLocal());
  }

  /// Phân loại thông báo dựa trên title.
  _NotifCategory _getCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('xe buýt') ||
        lower.contains('xe sắp') ||
        lower.contains('khởi hành')) {
      return _NotifCategory(Icons.directions_bus_rounded, AppColors.notifBus);
    }
    if (lower.contains('điểm danh') ||
        lower.contains('lên xe') ||
        lower.contains('an toàn')) {
      return _NotifCategory(
          Icons.check_circle_rounded, AppColors.notifSuccess);
    }
    if (lower.contains('phản hồi') ||
        lower.contains('tin nhắn') ||
        lower.contains('xác nhận')) {
      return _NotifCategory(Icons.forum_rounded, AppColors.notifFeedback);
    }
    if (lower.contains('về nhà') ||
        lower.contains('bàn giao') ||
        lower.contains('xuống xe')) {
      return _NotifCategory(
          Icons.how_to_reg_rounded, AppColors.notifSuccess);
    }
    if (lower.contains('hệ thống') ||
        lower.contains('cập nhật') ||
        lower.contains('bảo trì')) {
      return _NotifCategory(
          Icons.verified_user_rounded, AppColors.notifSystem);
    }
    if (lower.contains('liên kết') || lower.contains('tài khoản')) {
      return _NotifCategory(Icons.link_rounded, AppColors.notifSystem);
    }
    if (lower.contains('thanh toán') || lower.contains('giao dịch')) {
      return _NotifCategory(Icons.payment_rounded, AppColors.notifFeedback);
    }
    if (lower.contains('đặt vé')) {
      return _NotifCategory(
          Icons.confirmation_number_rounded, AppColors.notifSuccess);
    }
    return _NotifCategory(Icons.notifications_rounded, AppColors.notifBus);
  }
}

class _NotifCategory {
  final IconData icon;
  final Color color;

  const _NotifCategory(this.icon, this.color);
}
