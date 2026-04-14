import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/driver_stats_controller.dart';

class DriverStatsWeeklyChartWidget extends StatelessWidget {
  final List<DailyStats> weeklyData;
  final int maxValue;

  const DriverStatsWeeklyChartWidget({
    super.key,
    required this.weeklyData,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C252E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biểu đồ tuần này',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getWeekRangeLabel(),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: AppConstants.paddingLG),
          SizedBox(
            height: 185,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.asMap().entries.map((entry) {
                return _buildBar(context, entry.value, entry.key, isDark);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Nhãn khoảng ngày (ví dụ: "07/04 - 13/04").
  String _getWeekRangeLabel() {
    if (weeklyData.isEmpty) return '';
    final formatter = DateFormat('dd/MM');
    final start = formatter.format(weeklyData.first.date);
    final end = formatter.format(weeklyData.last.date);
    return '$start - $end';
  }

  /// Build 1 cột trong biểu đồ.
  Widget _buildBar(
    BuildContext context,
    DailyStats stats,
    int index,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday = stats.date.year == now.year &&
        stats.date.month == now.month &&
        stats.date.day == now.day;
    final isFuture = stats.date.isAfter(now);

    // Tính chiều cao cột (max 120px)
    const maxBarHeight = 120.0;
    final barHeight = maxValue > 0
        ? (stats.total / maxValue) * maxBarHeight
        : 0.0;

    // Màu cột
    Color barColor;
    if (isFuture) {
      barColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    } else if (isToday) {
      barColor = theme.colorScheme.primary;
    } else if (stats.total == stats.completed && stats.total > 0) {
      barColor = AppColors.success;
    } else {
      barColor = theme.colorScheme.primary.withValues(alpha: 0.5);
    }

    // Nhãn ngày (T2, T3, ..., CN)
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final dayLabel = index < dayLabels.length ? dayLabels[index] : '';

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Giá trị trên cột
          if (stats.total > 0)
            Text(
              '${stats.total}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isToday
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.grey[400] : Colors.grey[500]),
              ),
            ),
          const SizedBox(height: 4),
          // Cột
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            height: barHeight > 0 ? barHeight : 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Nhãn ngày
          Container(
            padding: isToday
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                : null,
            decoration: isToday
                ? BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Text(
              dayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
