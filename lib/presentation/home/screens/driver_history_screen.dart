import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_model.dart';
import '../controllers/driver_history_controller.dart';
import '../controllers/driver_home_controller.dart';
import 'driver_trip_detail_screen.dart';

class DriverHistoryScreen extends StatefulWidget {
  final DriverHistoryController controller;
  final DriverHomeController driverHomeController;

  const DriverHistoryScreen({
    super.key,
    required this.controller,
    required this.driverHomeController,
  });

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return Column(
            children: [
              _buildAppBar(theme, isDark, backgroundColor),
              _buildDateSelector(theme, isDark),
              Expanded(child: _buildBody(theme, isDark)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDark, Color bgColor) {
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
                'Lịch sử chuyến đi',
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

  Widget _buildDateSelector(ThemeData theme, bool isDark) {
    final ctrl = widget.controller;
    final now = DateTime.now();
    final selected = ctrl.selectedDate;
    final isToday = selected.year == now.year &&
        selected.month == now.month &&
        selected.day == now.day;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingSM + 4,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildDateNavButton(
            icon: Icons.chevron_left_rounded,
            theme: theme,
            isDark: isDark,
            onTap: () {
              ctrl.changeDate(selected.subtract(const Duration(days: 1)));
            },
          ),
          const SizedBox(width: AppConstants.paddingSM),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDate(context, ctrl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMD,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isToday
                          ? 'Hôm nay, ${DateFormat('dd/MM/yyyy').format(selected)}'
                          : DateFormat('EEEE, dd/MM/yyyy', 'vi').format(selected),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
          _buildDateNavButton(
            icon: Icons.chevron_right_rounded,
            theme: theme,
            isDark: isDark,
            onTap: isToday
                ? null
                : () {
                    ctrl.changeDate(selected.add(const Duration(days: 1)));
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavButton({
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark ? AppColors.darkCard : AppColors.lightCard)
                  .withValues(alpha: 0.5)
              : isDark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDisabled
              ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    final ctrl = widget.controller;

    if (ctrl.isLoading) {
      return _buildLoadingSkeleton(theme, isDark);
    }

    if (ctrl.errorMessage != null) {
      return _buildError(theme, isDark, ctrl);
    }

    if (ctrl.trips.isEmpty) {
      return _buildEmpty(theme, isDark);
    }

    return RefreshIndicator(
      onRefresh: () => ctrl.loadTrips(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        itemCount: ctrl.trips.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppConstants.paddingSM),
        itemBuilder: (context, index) {
          return _buildTripCard(context, ctrl.trips[index], theme, isDark);
        },
      ),
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    TripModel trip,
    ThemeData theme,
    bool isDark,
  ) {
    final statusInfo = _getStatusInfo(trip.status);
    final route = trip.route;
    final directionLabel = trip.isDropOff ? 'Trả về' : 'Đón đi';
    final directionIcon = trip.isDropOff
        ? Icons.home_rounded
        : Icons.school_rounded;
    final timeStr = _formatTripTime(trip);
    final stationCount = route?.stations.length ?? 0;

    return GestureDetector(
      onTap: () => _openTripDetail(trip),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_bus_filled,
                    color: statusInfo.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route?.name ?? 'Chuyến đi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route?.routeCode ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusInfo.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusInfo.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withValues(alpha: 0.5)
                    : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Row(
                children: [
                  _buildInfoChip(
                    icon: directionIcon,
                    label: directionLabel,
                    theme: theme,
                  ),
                  _buildVerticalDivider(theme),
                  _buildInfoChip(
                    icon: Icons.access_time_rounded,
                    label: timeStr,
                    theme: theme,
                  ),
                  _buildVerticalDivider(theme),
                  _buildInfoChip(
                    icon: Icons.location_on_outlined,
                    label: '$stationCount trạm',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      itemCount: 4,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.paddingSM),
      itemBuilder: (context, index) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, bool isDark, DriverHistoryController ctrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMD),
            Text(
              ctrl.errorMessage ?? 'Đã xảy ra lỗi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMD),
            TextButton.icon(
              onPressed: () => ctrl.loadTrips(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 40,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMD),
            Text(
              'Không có chuyến đi nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy chọn ngày khác để xem lịch sử chuyến đi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DriverHistoryController ctrl,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ctrl.changeDate(picked);
    }
  }

  void _openTripDetail(TripModel trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverTripDetailScreen(
          allTrips: [trip],
          initialTripIndex: 0,
          controller: widget.driverHomeController,
        ),
      ),
    );
  }

  String _formatTripTime(TripModel trip) {
    if (trip.startTime != null && trip.endTime != null) {
      final start = DateFormat('HH:mm').format(trip.startTime!.toLocal());
      final end = DateFormat('HH:mm').format(trip.endTime!.toLocal());
      return '$start - $end';
    }
    if (trip.startTime != null) {
      return DateFormat('HH:mm').format(trip.startTime!.toLocal());
    }
    if (trip.route?.estimatedTime != null) {
      return DateFormat('HH:mm').format(trip.route!.estimatedTime!.toLocal());
    }
    return '--:--';
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return _StatusInfo('Hoàn thành', AppColors.success);
      case 'IN_PROGRESS':
        return _StatusInfo('Đang chạy', AppColors.warning);
      case 'CANCELLED':
        return _StatusInfo('Đã hủy', AppColors.error);
      case 'PENDING':
      default:
        return _StatusInfo('Chờ khởi hành', AppColors.primary);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}
