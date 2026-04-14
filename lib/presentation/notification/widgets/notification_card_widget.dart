import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationCardWidget extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  State<NotificationCardWidget> createState() => _NotificationCardWidgetState();
}

class _NotificationCardWidgetState extends State<NotificationCardWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final notif = widget.notification;
    final category = _getCategory(notif.title);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.99 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          margin: const EdgeInsets.only(bottom: AppConstants.paddingSM + 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : colorScheme.surface,
            borderRadius: BorderRadius.circular(
              AppConstants.notificationCardRadius,
            ),
            border: Border.all(
              color: notif.isRead
                  ? (isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFF3F4F6))
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: notif.isRead
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon theo loại thông báo
              _buildIcon(category, isDark),
              const SizedBox(width: AppConstants.paddingMD),
              // Nội dung
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: notif.isRead ? 0 : AppConstants.paddingMD,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notif.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                color: notif.isRead
                                    ? (isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF4B5563))
                                    : colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingSM),
                          Text(
                            _formatTime(notif.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: notif.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w500,
                              color: notif.isRead
                                  ? (isDark
                                      ? AppColors.darkTextHint
                                      : AppColors.lightTextHint)
                                  : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: notif.isRead
                              ? (isDark
                                  ? AppColors.darkTextHint
                                  : AppColors.lightTextHint)
                              : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF4B5563)),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Chấm tròn chưa đọc
              if (!notif.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: AppConstants.notificationDotSize,
                    height: AppConstants.notificationDotSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icon tròn với background nhạt theo loại thông báo.
  Widget _buildIcon(_NotifCategory category, bool isDark) {
    return Container(
      width: AppConstants.notificationIconSize,
      height: AppConstants.notificationIconSize,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        category.icon,
        size: AppConstants.iconSizeMD,
        color: category.color,
      ),
    );
  }

  /// Format thời gian hiển thị (chuyển UTC → giờ địa phương).
  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    if (local.isAfter(todayStart)) {
      return DateFormat('HH:mm').format(local);
    } else if (local.isAfter(yesterdayStart)) {
      return DateFormat('HH:mm').format(local);
    } else {
      return DateFormat('dd/MM').format(local);
    }
  }

  /// Phân loại thông báo dựa trên title để chọn icon + màu.
  _NotifCategory _getCategory(String title) {
    final lower = title.toLowerCase();

    // ─── Trip lifecycle (driver) ───
    if (lower.contains('đến trạm') || lower.contains('station')) {
      return _NotifCategory(Icons.location_on_rounded, AppColors.notifBus);
    }
    if (lower.contains('hoàn thành') || lower.contains('kết thúc')) {
      return _NotifCategory(Icons.flag_rounded, AppColors.notifSuccess);
    }

    if (lower.contains('xe buýt') ||
        lower.contains('xe sắp') ||
        lower.contains('khởi hành') ||
        lower.contains('bắt đầu')) {
      return _NotifCategory(Icons.directions_bus_rounded, AppColors.notifBus);
    }
    if (lower.contains('điểm danh') ||
        lower.contains('lên xe') ||
        lower.contains('an toàn')) {
      return _NotifCategory(Icons.check_circle_rounded, AppColors.notifSuccess);
    }
    if (lower.contains('phản hồi') ||
        lower.contains('tin nhắn') ||
        lower.contains('xác nhận')) {
      return _NotifCategory(Icons.forum_rounded, AppColors.notifFeedback);
    }
    if (lower.contains('về nhà') ||
        lower.contains('bàn giao') ||
        lower.contains('xuống xe')) {
      return _NotifCategory(Icons.how_to_reg_rounded, AppColors.notifSuccess);
    }
    if (lower.contains('hệ thống') ||
        lower.contains('cập nhật') ||
        lower.contains('bảo trì')) {
      return _NotifCategory(Icons.verified_user_rounded, AppColors.notifSystem);
    }
    if (lower.contains('liên kết') || lower.contains('tài khoản')) {
      return _NotifCategory(Icons.link_rounded, AppColors.notifSystem);
    }
    if (lower.contains('thanh toán') || lower.contains('giao dịch')) {
      return _NotifCategory(Icons.payment_rounded, AppColors.notifFeedback);
    }
    if (lower.contains('nghỉ phép') || lower.contains('xin nghỉ')) {
      return _NotifCategory(Icons.event_busy_rounded, AppColors.notifFeedback);
    }
    return _NotifCategory(Icons.notifications_rounded, AppColors.notifBus);
  }
}

/// Cặp icon + màu cho từng loại thông báo.
class _NotifCategory {
  final IconData icon;
  final Color color;

  const _NotifCategory(this.icon, this.color);
}
