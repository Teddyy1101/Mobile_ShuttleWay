import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/activity_model.dart';

class RecentActivitiesWidget extends StatelessWidget {
  final List<ActivityModel> activities;

  const RecentActivitiesWidget({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        // Timeline layout
        ...List.generate(activities.length, (index) {
          final isLast = index == activities.length - 1;
          return _TimelineItem(
            activity: activities[index],
            isLast: isLast,
          );
        }),
      ],
    );
  }
}

/// Một hàng trong timeline — icon tròn bên trái, vertical line nối, content bên phải.
class _TimelineItem extends StatelessWidget {
  final ActivityModel activity;
  final bool isLast;

  const _TimelineItem({
    required this.activity,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = _getIconColor(activity.iconType);

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
                    _getIcon(activity.iconType),
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
                          activity.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingSM),
                      Text(
                        activity.time,
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
                    activity.subtitle,
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

  IconData _getIcon(String iconType) {
    switch (iconType) {
      case 'boarded':
        return Icons.login_rounded;
      case 'bus_arriving':
        return Icons.notifications_active_rounded;
      case 'attendance':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getIconColor(String iconType) {
    switch (iconType) {
      case 'boarded':
        return AppColors.success;
      case 'bus_arriving':
        return AppColors.primary;
      case 'attendance':
        return const Color(0xFF9E9E9E); // grey for completed
      default:
        return AppColors.primary;
    }
  }
}
