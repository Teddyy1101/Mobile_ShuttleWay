import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/trip_model.dart';
import '../controllers/schedule_controller.dart';
import 'leave_request_screen.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/leave_request_controller.dart';
import '../widgets/route_detail_bottom_sheet.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../notification/screens/notification_screen.dart';
import 'ticket_history_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final ScheduleController scheduleController;
  final ProfileController profileController;
  final LeaveRequestController leaveRequestController;
  final NotificationController notificationController;

  const ScheduleScreen({
    super.key,
    required this.scheduleController,
    required this.profileController,
    required this.leaveRequestController,
    required this.notificationController,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late PageController _weekPageController;

  // Tuần gốc (chứa ngày hôm nay) nằm ở page giữa
  static const int _initialPage = 500;

  @override
  void initState() {
    super.initState();
    _weekPageController = PageController(initialPage: _initialPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Nếu là PARENT → tự động chọn học sinh đầu tiên
      if (widget.profileController.isParent) {
        final children = widget.profileController.linkedUsers;
        if (children.isNotEmpty &&
            widget.scheduleController.selectedChild == null) {
          widget.scheduleController.selectChild(children.first);
          return; // selectChild sẽ gọi fetchTrips
        }
      }
      widget.scheduleController.fetchTrips();
    });
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  /// Tính ngày Monday của tuần chứa [date].
  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Tính Monday của tuần tại page [index] (so với tuần gốc).
  DateTime _mondayForPage(int pageIndex) {
    final today = DateTime.now();
    final todayMonday = _startOfWeek(today);
    final offset = pageIndex - _initialPage;
    return todayMonday.add(Duration(days: offset * 7));
  }

  void _navigateToLeaveRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeaveRequestScreen(
          profileController: widget.profileController,
          leaveRequestController: widget.leaveRequestController,
        ),
      ),
    );
  }

  /// Nhảy về tuần chứa ngày hôm nay.
  void _goToToday() {
    widget.scheduleController.setSelectedDate(DateTime.now());
    _weekPageController.animateToPage(
      _initialPage,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
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
            _buildAppBar(theme, isDark),
            _buildCalendarHeader(theme, isDark),
            if (widget.profileController.isParent)
              _buildChildSelector(theme, isDark),
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
                            padding:
                                const EdgeInsets.all(AppConstants.paddingMD),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDateAndLeaveAction(theme, isDark),
                                const SizedBox(height: AppConstants.paddingLG),
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

  // ─── App Bar ─────────────────────────────────────────────────

  Widget _buildAppBar(ThemeData theme, bool isDark) {
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
          // Icon chuông với badge động
          ListenableBuilder(
            listenable: widget.notificationController,
            builder: (context, _) {
              final hasUnread = widget.notificationController.unreadCount > 0;
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
                              controller: widget.notificationController,
                              onViewTicket: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TicketHistoryScreen(
                                      profileController: widget.profileController,
                                      children: widget.profileController.isParent
                                          ? widget.profileController.linkedUsers
                                          : [],
                                    ),
                                  ),
                                );
                              },
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

  // ─── Calendar ────────────────────────────────────────────────

  Widget _buildCalendarHeader(ThemeData theme, bool isDark) {
    return ListenableBuilder(
      listenable: widget.scheduleController,
      builder: (context, _) {
        final selectedDate = widget.scheduleController.selectedDate;

        return Container(
          color: isDark ? AppColors.darkCard : Colors.white,
          padding: const EdgeInsets.only(bottom: AppConstants.paddingSM),
          child: Column(
            children: [
              // Điều hướng tháng + nút Hôm nay
              Padding(
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
                            (_weekPageController.page?.round() ?? _initialPage) -
                                1;
                        _weekPageController.animateToPage(
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
                      onTap: _isSelectedDateToday ? null : _goToToday,
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
                          if (!_isSelectedDateToday) ...[
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
                            (_weekPageController.page?.round() ?? _initialPage) +
                                1;
                        _weekPageController.animateToPage(
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
              ),
              // Tuần với PageView (vuốt ngang)
              SizedBox(
                height: 64,
                child: PageView.builder(
                  controller: _weekPageController,
                  onPageChanged: (page) {
                    // Chọn ngày đầu tuần khi vuốt,
                    // nhưng giữ ngày đã chọn nếu vẫn nằm trong tuần đó
                    final monday = _mondayForPage(page);
                    final current = widget.scheduleController.selectedDate;
                    final currentMonday = _startOfWeek(current);
                    if (currentMonday != monday) {
                      // Nếu tuần khác → chọn cùng thứ trong tuần hoặc Monday
                      final sameWeekday =
                          monday.add(Duration(days: current.weekday - 1));
                      widget.scheduleController.setSelectedDate(sameWeekday);
                    }
                  },
                  itemBuilder: (context, pageIndex) {
                    final monday = _mondayForPage(pageIndex);
                    return _buildWeekRow(
                      monday,
                      selectedDate,
                      theme,
                      isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekRow(
    DateTime monday,
    DateTime selectedDate,
    ThemeData theme,
    bool isDark,
  ) {
    const weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
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
            onTap: () => widget.scheduleController.setSelectedDate(date),
            child: SizedBox(
              width: (MediaQuery.of(context).size.width - 24) / 7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekdayLabels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isWeekend
                              ? AppColors.error.withValues(alpha: 0.7)
                              : (isDark ? Colors.grey[500] : Colors.grey[400]),
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

  // ─── Child Selector (PARENT only) ───────────────────────────

  Widget _buildChildSelector(ThemeData theme, bool isDark) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.profileController,
        widget.scheduleController,
      ]),
      builder: (context, _) {
        final children = widget.profileController.linkedUsers;
        final selectedChild = widget.scheduleController.selectedChild;

        if (children.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMD,
            vertical: AppConstants.paddingSM,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[200]!,
              ),
            ),
          ),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final child = children[index];
                final isSelected = selectedChild?.id == child.id;
                return _buildChildChip(child, isSelected, theme, isDark);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildChildChip(
    ChildModel child,
    bool isSelected,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => widget.scheduleController.selectChild(child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingSM + 4,
          vertical: AppConstants.paddingXS + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isSelected
                  ? Colors.white.withValues(alpha: 0.3)
                  : theme.colorScheme.primary.withValues(alpha: 0.15),
              backgroundImage: child.avatarUrl != null
                  ? NetworkImage(child.avatarUrl!)
                  : null,
              child: child.avatarUrl == null
                  ? Text(
                      child.fullName.isNotEmpty
                          ? child.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppConstants.paddingSM),
            Text(
              child.fullName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Date Header + Leave Action ─────────────────────────────

  Widget _buildDateAndLeaveAction(ThemeData theme, bool isDark) {
    final selectedDate = widget.scheduleController.selectedDate;
    final DateFormat formatterDay = DateFormat('EEEE, dd MMMM', 'vi_VN');

    String dayStr = formatterDay.format(selectedDate);
    if (dayStr.isNotEmpty) {
      dayStr = dayStr[0].toUpperCase() + dayStr.substring(1);
    }

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
        InkWell(
          onTap: _navigateToLeaveRequest,
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 6),
                const Text(
                  'Đăng ký nghỉ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Trips List ─────────────────────────────────────────────

  Widget _buildTripsList(ThemeData theme, bool isDark) {
    if (widget.scheduleController.isLoading) {
      return _buildLoadingShimmer(isDark);
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : Colors.grey[100],
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
              .map((entry) => _buildTripItem(theme, isDark, entry.value, entry.key))
              .toList(),
        ),
      ],
    );
  }

  // ─── Trip Item Card ─────────────────────────────────────────

  Widget _buildTripItem(
    ThemeData theme,
    bool isDark,
    TripModel trip,
    int index,
  ) {
    final isMorning = trip.route?.shiftType == 'MORNING' ||
        (trip.startTime != null && trip.startTime!.hour < 12);
    final bool isCompleted = trip.status == 'COMPLETED';
    final bool isInProgress = trip.status == 'IN_PROGRESS';

    // Trạng thái hiển thị: ưu tiên attendanceStatus (cá nhân) > trip.status
    final displayStatus = trip.attendanceStatus ?? trip.status;

    // Format thời gian
    final startStr = trip.startTime != null
        ? DateFormat('HH:mm').format(trip.startTime!)
        : (trip.route?.shiftType == 'MORNING' ? '06:30' : '16:30');

    final endStr = trip.endTime != null
        ? DateFormat('HH:mm').format(trip.endTime!)
        : _estimateEndTime(trip);

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
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success
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
                  isCompleted ? Icons.check : Icons.directions_bus,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMD),
            // Card content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(
                    color: isCompleted
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[100]!)
                        : theme.colorScheme.primary
                            .withValues(alpha: 0.2),
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
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMD),
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
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(
                            AppConstants.paddingMD),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: icon + name + badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isMorning
                                        ? AppColors.primary
                                            .withValues(alpha: 0.1)
                                        : Colors.orange
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.radiusSM),
                                  ),
                                  child: Icon(
                                    isMorning
                                        ? Icons.wb_twilight
                                        : Icons.wb_sunny_outlined,
                                    color: isMorning
                                        ? AppColors.primary
                                        : Colors.orange,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isMorning
                                            ? 'Chuyến sáng'
                                            : 'Chuyến chiều',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 14,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$startStr - $endStr',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusBadge(displayStatus, theme),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Info rows
                            _buildInfoRow(
                              Icons.directions_bus_outlined,
                              'Tuyến ${trip.route?.routeCode ?? 'N/A'} - ${trip.bus?.licensePlate ?? 'N/A'}',
                              isDark,
                            ),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              Icons.badge_outlined,
                              'Tài xế: ${trip.driver?.fullName ?? 'Chưa phân công'}',
                              isDark,
                            ),
                            // Nút hành động (chỉ cho trip chưa hoàn thành)
                            if (!isCompleted) ...[
                              const SizedBox(height: 12),
                              Container(
                                height: 1,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey[200],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      'Chi tiết lộ trình',
                                      theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      theme.colorScheme.primary,
                                      () {
                                        _showRouteDetailDialog(context, trip);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildActionButton(
                                      'Liên hệ tài xế',
                                      isDark
                                          ? Colors.grey[800]!
                                          : Colors.grey[100]!,
                                      isDark
                                          ? Colors.grey[300]!
                                          : Colors.grey[600]!,
                                      () {
                                        // TODO: Liên hệ tài xế
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  void _showRouteDetailDialog(BuildContext context, TripModel trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteDetailBottomSheet(trip: trip),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    String label;
    Color color;

    switch (status) {
      case 'COMPLETED':
        label = 'ĐÃ HOÀN THÀNH';
        color = AppColors.success;
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

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
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

  Widget _buildActionButton(
    String label,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// Dự kiến giờ kết thúc từ estimatedTime + totalDuration.
  String _estimateEndTime(TripModel trip) {
    if (trip.route == null) return '--:--';
    // Sử dụng shiftType để ước lượng
    if (trip.route!.shiftType == 'MORNING') return '07:15';
    return '17:15';
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Column(
      children: List.generate(2, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.paddingMD),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline node placeholder
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
              // Card placeholder
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
