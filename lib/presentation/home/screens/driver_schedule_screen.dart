import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_model.dart';
import '../controllers/driver_schedule_controller.dart';
import '../controllers/driver_home_controller.dart';
import '../widgets/driver_schedule_calendar_widget.dart';
import '../widgets/driver_schedule_trip_card_widget.dart';
import 'driver_trip_detail_screen.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../notification/screens/notification_screen.dart';

class DriverScheduleScreen extends StatefulWidget {
  final DriverScheduleController scheduleController;
  final DriverHomeController driverHomeController;
  final NotificationController notificationController;

  const DriverScheduleScreen({
    super.key,
    required this.scheduleController,
    required this.driverHomeController,
    required this.notificationController,
  });

  @override
  State<DriverScheduleScreen> createState() => _DriverScheduleScreenState();
}

class _DriverScheduleScreenState extends State<DriverScheduleScreen> {
  late PageController _weekPageController;
  static const int _initialPage = 500;

  @override
  void initState() {
    super.initState();
    _weekPageController = PageController(initialPage: _initialPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.scheduleController.fetchTrips();
    });
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  bool get _isSelectedDateToday {
    final now = DateTime.now();
    final d = widget.scheduleController.selectedDate;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _DriverScheduleAppBar(
              notificationController: widget.notificationController,
            ),
            DriverScheduleCalendarWidget(
              controller: widget.scheduleController,
              weekPageController: _weekPageController,
              initialPage: _initialPage,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.scheduleController,
                builder: (context, _) {
                  return RefreshIndicator(
                    onRefresh: () => widget.scheduleController.fetchTrips(),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(
                                AppConstants.paddingMD),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDateHeader(theme, isDark),
                                const SizedBox(
                                    height: AppConstants.paddingLG),
                                _buildTripsList(theme, isDark),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header ngày đã chọn + tổng số chuyến.
  Widget _buildDateHeader(ThemeData theme, bool isDark) {
    final selectedDate = widget.scheduleController.selectedDate;
    final DateFormat formatterDay = DateFormat('EEEE, dd MMMM', 'vi_VN');

    String dayStr = formatterDay.format(selectedDate);
    if (dayStr.isNotEmpty) {
      dayStr = dayStr[0].toUpperCase() + dayStr.substring(1);
    }

    final tripCount = widget.scheduleController.todayTrips.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSelectedDateToday ? 'Hôm nay' : 'Ngày đã chọn',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dayStr,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        // Badge tổng số chuyến
        if (tripCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_bus_filled,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '$tripCount chuyến',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Danh sách chuyến đi (timeline).
  Widget _buildTripsList(ThemeData theme, bool isDark) {
    if (widget.scheduleController.isLoading) {
      return _DriverScheduleLoadingShimmer(isDark: isDark);
    }

    if (widget.scheduleController.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingXL),
          child: Text(
            widget.scheduleController.error!,
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final trips = widget.scheduleController.todayTrips;

    if (trips.isEmpty) {
      return _DriverScheduleEmptyState(isDark: isDark);
    }

    return Stack(
      children: [
        // Dòng kẻ dọc timeline
        Positioned(
          left: 19,
          top: 24,
          bottom: 24,
          child: Container(
            width: 2,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
        ),
        Column(
          children: trips
              .asMap()
              .entries
              .map((entry) => DriverScheduleTripCardWidget(
                    trip: entry.value,
                    index: entry.key,
                    onViewDetail: () => _openTripDetail(entry.value),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Mở chi tiết chuyến đi.
  void _openTripDetail(TripModel trip) {
    final allTrips = widget.scheduleController.todayTrips;
    final idx = allTrips.indexWhere((t) => t.id == trip.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverTripDetailScreen(
          allTrips: allTrips,
          initialTripIndex: idx >= 0 ? idx : 0,
          controller: widget.driverHomeController,
        ),
      ),
    );
  }
}

/// App bar cho màn hình lịch trình tài xế.
class _DriverScheduleAppBar extends StatelessWidget {
  final NotificationController notificationController;

  const _DriverScheduleAppBar({required this.notificationController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingSM + 4,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Lịch trình',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          ListenableBuilder(
            listenable: notificationController,
            builder: (context, _) {
              final hasUnread = notificationController.unreadCount > 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationScreen(
                              controller: notificationController,
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        size: AppConstants.iconSizeSM,
                        color: theme.colorScheme.onSurface,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 8,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightBackground,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Empty state khi không có chuyến.
class _DriverScheduleEmptyState extends StatelessWidget {
  final bool isDark;

  const _DriverScheduleEmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_outlined,
                size: 36,
                color: isDark ? Colors.grey[600] : Colors.grey[350],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có chuyến đi nào',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Không tìm thấy lịch trình cho ngày này',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading shimmer khi đang tải dữ liệu.
class _DriverScheduleLoadingShimmer extends StatelessWidget {
  final bool isDark;

  const _DriverScheduleLoadingShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(2, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.paddingMD),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMD),
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMD),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusSM),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 80,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 180,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
