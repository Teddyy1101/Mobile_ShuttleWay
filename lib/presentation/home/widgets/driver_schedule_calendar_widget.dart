import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/driver_schedule_controller.dart';

class DriverScheduleCalendarWidget extends StatelessWidget {
  final DriverScheduleController controller;
  final PageController weekPageController;
  final int initialPage;
  
  const DriverScheduleCalendarWidget({
    super.key,
    required this.controller,
    required this.weekPageController,
    this.initialPage = 500,
  });

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime _mondayForPage(int pageIndex) {
    final today = DateTime.now();
    final todayMonday = _startOfWeek(today);
    final offset = pageIndex - initialPage;
    return todayMonday.add(Duration(days: offset * 7));
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  void _goToToday() {
    controller.setSelectedDate(DateTime.now());
    weekPageController.animateToPage(
      initialPage,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selectedDate = controller.selectedDate;
        final isSelectedToday = _isToday(selectedDate);

        return Container(
          color: isDark ? AppColors.darkCard : Colors.white,
          padding: const EdgeInsets.only(bottom: AppConstants.paddingSM),
          child: Column(
            children: [
              _buildMonthNav(theme, isDark, selectedDate, isSelectedToday),
              _buildWeekPageView(theme, isDark, selectedDate),
            ],
          ),
        );
      },
    );
  }

  /// Điều hướng tháng + nút "Hôm nay".
  Widget _buildMonthNav(
    ThemeData theme,
    bool isDark,
    DateTime selectedDate,
    bool isSelectedToday,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSM,
        vertical: AppConstants.paddingSM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: () {
              final prevPage =
                  (weekPageController.page?.round() ?? initialPage) - 1;
              weekPageController.animateToPage(
                prevPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
            ),
          ),
          GestureDetector(
            onTap: isSelectedToday ? null : _goToToday,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tháng ${selectedDate.month}, ${selectedDate.year}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                if (!isSelectedToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Hôm nay',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            onPressed: () {
              final nextPage =
                  (weekPageController.page?.round() ?? initialPage) + 1;
              weekPageController.animateToPage(
                nextPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }

  /// PageView tuần (vuốt ngang).
  Widget _buildWeekPageView(
    ThemeData theme,
    bool isDark,
    DateTime selectedDate,
  ) {
    return SizedBox(
      height: 64,
      child: PageView.builder(
        controller: weekPageController,
        onPageChanged: (page) {
          final monday = _mondayForPage(page);
          final current = controller.selectedDate;
          final currentMonday = _startOfWeek(current);
          if (currentMonday != monday) {
            final sameWeekday =
                monday.add(Duration(days: current.weekday - 1));
            controller.setSelectedDate(sameWeekday);
          }
        },
        itemBuilder: (context, pageIndex) {
          final monday = _mondayForPage(pageIndex);
          return _WeekRow(
            monday: monday,
            selectedDate: selectedDate,
            onDateSelected: controller.setSelectedDate,
          );
        },
      ),
    );
  }
}

/// Hàng 7 ngày trong tuần.
class _WeekRow extends StatelessWidget {
  final DateTime monday;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekRow({
    required this.monday,
    required this.selectedDate,
    required this.onDateSelected,
  });

  static const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = monday.add(Duration(days: index));
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          final isWeekend = index >= 5;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: SizedBox(
              width: (MediaQuery.of(context).size.width - 24) / 7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _weekdayLabels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isWeekend
                              ? AppColors.error.withValues(alpha: 0.7)
                              : (isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
