import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/driver_trip_repository.dart';
import '../controllers/driver_stats_controller.dart';
import '../widgets/driver_stats_summary_card_widget.dart';
import '../widgets/driver_stats_weekly_chart_widget.dart';

class DriverStatsScreen extends StatefulWidget {
  final DriverTripRepository driverTripRepository;

  const DriverStatsScreen({
    super.key,
    required this.driverTripRepository,
  });

  @override
  State<DriverStatsScreen> createState() => _DriverStatsScreenState();
}

class _DriverStatsScreenState extends State<DriverStatsScreen> {
  late final DriverStatsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DriverStatsController(widget.driverTripRepository);
    _controller.loadStats();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildAppBar(theme, isDark),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return _buildLoading(theme);
                }
                if (_controller.error != null) {
                  return _buildError(theme, isDark);
                }
                return _buildBody(context, theme, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDark) {
    final bgColor = theme.scaffoldBackgroundColor;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXS,
          vertical: AppConstants.paddingSM,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: const CircleBorder(),
              ),
            ),
            Expanded(
              child: Text(
                'Thống kê hoạt động',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppConstants.avatarSizeMD),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          Text(
            'Đang tải thống kê...',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMD),
            Text(
              _controller.error ?? 'Đã xảy ra lỗi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: AppConstants.paddingLG),
            SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: () => _controller.loadStats(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMD),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, bool isDark) {
    return RefreshIndicator(
      onRefresh: () => _controller.loadStats(),
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Section: Hôm nay ───
            _buildSectionTitle('HÔM NAY', isDark),
            const SizedBox(height: AppConstants.paddingSM),
            _buildTodayStats(theme, isDark),
            const SizedBox(height: AppConstants.paddingLG),

            // ─── Section: Biểu đồ tuần ───
            DriverStatsWeeklyChartWidget(
              weeklyData: _controller.weeklyData,
              maxValue: _controller.maxDailyTrips,
            ),
            const SizedBox(height: AppConstants.paddingLG),

            // ─── Section: Tổng quan tuần ───
            _buildSectionTitle('TỔNG QUAN TUẦN', isDark),
            const SizedBox(height: AppConstants.paddingSM),
            _buildWeeklyOverview(theme, isDark),
            const SizedBox(height: AppConstants.paddingLG),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// 3 card thống kê hôm nay: Hoàn thành, Đang chạy, Chờ.
  Widget _buildTodayStats(ThemeData theme, bool isDark) {
    final stats = _controller.todayStats;

    return Row(
      children: [
        Expanded(
          child: DriverStatsSummaryCardWidget(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
            iconBgColor: AppColors.success.withValues(alpha: 0.12),
            value: '${stats.completed}',
            label: 'Hoàn thành',
          ),
        ),
        const SizedBox(width: AppConstants.paddingSM),
        Expanded(
          child: DriverStatsSummaryCardWidget(
            icon: Icons.directions_bus_filled_rounded,
            iconColor: AppColors.warning,
            iconBgColor: AppColors.warning.withValues(alpha: 0.12),
            value: '${stats.inProgress}',
            label: 'Đang chạy',
          ),
        ),
        const SizedBox(width: AppConstants.paddingSM),
        Expanded(
          child: DriverStatsSummaryCardWidget(
            icon: Icons.schedule_rounded,
            iconColor: theme.colorScheme.primary,
            iconBgColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            value: '${stats.pending}',
            label: 'Chờ',
          ),
        ),
      ],
    );
  }

  /// Tổng quan tuần: 3 card metric lớn.
  Widget _buildWeeklyOverview(ThemeData theme, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C252E) : Colors.white;
    final completionPercent =
        (_controller.weeklyCompletionRate * 100).toStringAsFixed(0);

    return Column(
      children: [
        // Row 1: Tổng chuyến + Tỷ lệ hoàn thành
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                theme: theme,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.route_rounded,
                iconColor: theme.colorScheme.primary,
                title: '${_controller.weeklyTotal}',
                subtitle: 'Tổng chuyến',
              ),
            ),
            const SizedBox(width: AppConstants.paddingSM),
            Expanded(
              child: _buildOverviewCard(
                theme: theme,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.pie_chart_rounded,
                iconColor: AppColors.success,
                title: '$completionPercent%',
                subtitle: 'Tỷ lệ hoàn thành',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingSM),
        // Row 2: Tổng HS phục vụ + Chuyến hoàn thành
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                theme: theme,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.people_alt_rounded,
                iconColor: AppColors.notifFeedback,
                title: '${_controller.weeklyStudents}',
                subtitle: 'Học sinh phục vụ',
              ),
            ),
            const SizedBox(width: AppConstants.paddingSM),
            Expanded(
              child: _buildOverviewCard(
                theme: theme,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
                title: '${_controller.weeklyCompleted}',
                subtitle: 'Chuyến hoàn thành',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card tổng quan tuần (dùng cho grid 2×2).
  Widget _buildOverviewCard({
    required ThemeData theme,
    required bool isDark,
    required Color cardColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
