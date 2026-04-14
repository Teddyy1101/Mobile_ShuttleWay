import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_model.dart';

class DriverScheduleTripCardWidget extends StatelessWidget {
  final TripModel trip;
  final int index;
  final VoidCallback? onViewDetail;

  const DriverScheduleTripCardWidget({
    super.key,
    required this.trip,
    required this.index,
    this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMorning = trip.route?.shiftType == 'MORNING' ||
        (trip.startTime != null && trip.startTime!.hour < 12);
    final isCompleted = trip.status == 'COMPLETED';

    final startStr = trip.startTime != null
        ? DateFormat('HH:mm').format(trip.startTime!)
        : (trip.route?.shiftType == 'MORNING' ? '06:30' : '16:30');
    final endStr = trip.endTime != null
        ? DateFormat('HH:mm').format(trip.endTime!)
        : (trip.route?.shiftType == 'MORNING' ? '07:15' : '17:15');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.paddingMD),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline node
            _buildTimelineNode(theme, isCompleted),
            const SizedBox(width: AppConstants.paddingMD),
            // Card content
            Expanded(
              child: _buildCard(
                theme, isDark, isMorning, isCompleted, startStr, endStr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Node tròn trên timeline.
  Widget _buildTimelineNode(ThemeData theme, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success
              : trip.status == 'IN_PROGRESS'
                  ? AppColors.warning
                  : theme.colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.scaffoldBackgroundColor,
            width: 4,
          ),
          boxShadow: isCompleted
              ? []
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Icon(
          isCompleted
              ? Icons.check
              : trip.status == 'IN_PROGRESS'
                  ? Icons.navigation_rounded
                  : Icons.directions_bus,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  /// Card chứa thông tin chuyến đi.
  Widget _buildCard(
    ThemeData theme,
    bool isDark,
    bool isMorning,
    bool isCompleted,
    String startStr,
    String endStr,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: isCompleted
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100]!)
              : trip.status == 'IN_PROGRESS'
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : theme.colorScheme.primary.withValues(alpha: 0.2),
          width: isCompleted ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: Stack(
          children: [
            // Accent left bar
            if (!isCompleted)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: trip.status == 'IN_PROGRESS'
                      ? AppColors.warning
                      : theme.colorScheme.primary,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, isDark, isMorning, startStr, endStr),
                  const SizedBox(height: 12),
                  _buildInfoRows(isDark),
                  if (!isCompleted) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[200],
                    ),
                    const SizedBox(height: 12),
                    _buildActions(theme, isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header: icon buổi + tên chuyến + badge trạng thái.
  Widget _buildHeader(
    ThemeData theme,
    bool isDark,
    bool isMorning,
    String startStr,
    String endStr,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMorning
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
          child: Icon(
            isMorning ? Icons.wb_twilight : Icons.wb_sunny_outlined,
            color: isMorning ? AppColors.primary : Colors.orange,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isMorning ? 'Chuyến sáng' : 'Chuyến chiều',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(theme),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '$startStr - $endStr',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Badge trạng thái chuyến đi.
  Widget _buildStatusBadge(ThemeData theme) {
    String label;
    Color color;

    switch (trip.status) {
      case 'COMPLETED':
        label = 'HOÀN THÀNH';
        color = AppColors.success;
        break;
      case 'IN_PROGRESS':
        label = 'ĐANG CHẠY';
        color = AppColors.warning;
        break;
      default:
        label = 'SẮP TỚI';
        color = theme.colorScheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Dòng thông tin: tuyến, biển số, số HS, hướng đi.
  Widget _buildInfoRows(bool isDark) {
    final direction = trip.direction == 'PICK_UP' ? 'Đón HS' : 'Trả HS';

    return Column(
      children: [
        _infoRow(
          Icons.route_outlined,
          'Tuyến ${trip.route?.routeCode ?? 'N/A'} - ${trip.route?.name ?? ''}',
          isDark,
        ),
        const SizedBox(height: 4),
        _infoRow(
          Icons.directions_bus_outlined,
          'Biển số: ${trip.bus?.licensePlate ?? 'N/A'}',
          isDark,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _infoRow(
                Icons.people_alt_outlined,
                '${trip.attendanceCount} học sinh',
                isDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: trip.direction == 'PICK_UP'
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    trip.direction == 'PICK_UP'
                        ? Icons.login_rounded
                        : Icons.logout_rounded,
                    size: 12,
                    color: trip.direction == 'PICK_UP'
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    direction,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: trip.direction == 'PICK_UP'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Nút hành động: xem chi tiết.
  Widget _buildActions(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onViewDetail,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Xem chi tiết chuyến',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Row thông tin (icon + text).
  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon,
            size: 16, color: isDark ? Colors.grey[500] : Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
