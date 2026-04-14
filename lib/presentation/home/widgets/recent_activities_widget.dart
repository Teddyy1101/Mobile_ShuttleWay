import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/notification_model.dart';

/// Widget hiển thị các hoạt động (thông báo) gần đây theo dạng timeline.
/// Lấy dữ liệu thực từ [NotificationModel] thay vì mock ActivityModel.
class RecentActivitiesWidget extends StatelessWidget {
  final List<NotificationModel> notifications;

  const RecentActivitiesWidget({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Lọc chỉ thông báo liên quan đến chuyến đã hoàn thành
    final tripNotifications = notifications.where((n) {
      final lower = n.title.toLowerCase();
      return lower.contains('hoàn thành') ||
          lower.contains('kết thúc') ||
          lower.contains('khởi hành') ||
          lower.contains('bắt đầu') ||
          lower.contains('đến trạm') ||
          lower.contains('lên xe') ||
          lower.contains('xuống xe');
    }).toList();

    if (tripNotifications.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động gần đây',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLG),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 24,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(width: AppConstants.paddingSM),
                Expanded(
                  child: Text(
                    'Chưa có hoạt động nào',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final displayList = tripNotifications.take(4).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoạt động gần đây',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMD),
        // Timeline layout — tối đa 4 thông báo chuyến gần nhất
        ...List.generate(displayList.length, (index) {
          final isLast = index == displayList.length - 1;
          return _TimelineItem(
            notification: displayList[index],
            isLast: isLast,
          );
        }),
      ],
    );
  }
}

/// Một hàng trong timeline — icon tròn bên trái, vertical line nối, content bên phải.
class _TimelineItem extends StatelessWidget {
  final NotificationModel notification;
  final bool isLast;

  const _TimelineItem({
    required this.notification,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = _getIconFromTitle(notification.title);
    final iconColor = _getColorFromTitle(notification.title);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Timeline column: circle + line ───
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Circle icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.lightBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    size: AppConstants.iconSizeSM,
                    color: iconColor,
                  ),
                ),
                // Vertical connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.paddingMD),
          // ─── Content ───
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppConstants.paddingLG,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingSM),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lấy icon phù hợp dựa trên title thông báo.
  IconData _getIconFromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('khởi hành') || lower.contains('bắt đầu')) {
      return Icons.play_circle_rounded;
    }
    if (lower.contains('đến trạm')) {
      return Icons.notifications_active_rounded;
    }
    if (lower.contains('hoàn thành') || lower.contains('kết thúc')) {
      return Icons.check_circle_rounded;
    }
    if (lower.contains('lên xe')) {
      return Icons.login_rounded;
    }
    if (lower.contains('xuống xe')) {
      return Icons.logout_rounded;
    }
    if (lower.contains('hủy')) {
      return Icons.cancel_rounded;
    }
    return Icons.info_rounded;
  }

  /// Lấy màu icon dựa trên title thông báo.
  Color _getColorFromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('khởi hành') || lower.contains('bắt đầu')) {
      return AppColors.success;
    }
    if (lower.contains('đến trạm')) {
      return AppColors.primary;
    }
    if (lower.contains('hoàn thành') || lower.contains('kết thúc')) {
      return const Color(0xFF9E9E9E);
    }
    if (lower.contains('lên xe')) {
      return AppColors.success;
    }
    if (lower.contains('xuống xe')) {
      return AppColors.warning;
    }
    if (lower.contains('hủy')) {
      return AppColors.error;
    }
    return AppColors.primary;
  }

  /// Format thời gian thành dạng "HH:mm" hoặc "dd/MM".
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24 && now.day == dateTime.day) {
      return DateFormat('HH:mm').format(dateTime);
    }
    return DateFormat('dd/MM HH:mm').format(dateTime);
  }
}
