import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/fcm_service.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/network/notification_socket_service.dart';
import '../../../data/models/trip_model.dart';
import '../controllers/driver_home_controller.dart';
import '../controllers/parent_home_controller.dart';
import '../controllers/driver_schedule_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../map/screens/driver_map_screen.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/screens/driver_profile_screen.dart';
import '../../ticket/controllers/ticket_controller.dart';
import '../../ticket/controllers/payment_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../notification/screens/notification_screen.dart';
import '../controllers/leave_request_controller.dart';
import '../controllers/schedule_controller.dart';
import '../controllers/chatbot_controller.dart';
import 'driver_trip_detail_screen.dart';
import 'driver_schedule_screen.dart';
import 'driver_history_screen.dart';
import '../widgets/driver_header_widget.dart';
import '../widgets/driver_next_trip_card_widget.dart';
import '../widgets/driver_remaining_trips_widget.dart';
import '../widgets/driver_quick_actions_widget.dart';
import '../widgets/bottom_nav_bar_widget.dart';
import '../../map/widgets/trip_attendance_list_sheet.dart';
import '../../support/screens/driver_support_screen.dart';
import '../../support/controllers/support_controller.dart';
import '../controllers/driver_history_controller.dart';
import '../../../data/sources/support_ticket_api.dart';
import '../../../data/repositories/impl/api_support_repository.dart';

class DriverHomeScreen extends StatefulWidget {
  final DriverHomeController driverHomeController;
  final ParentHomeController parentHomeController;
  final ProfileController profileController;
  final AuthController authController;
  final ThemeController themeController;
  final TicketController ticketController;
  final PaymentController paymentController;
  final MapController mapController;
  final LeaveRequestController leaveRequestController;
  final ScheduleController scheduleController;
  final DriverScheduleController driverScheduleController;
  final NotificationController notificationController;
  final ChatbotController chatbotController;
  final FcmService fcmService;
  final DioClient dioClient;
  final SocketService socketService;
  final NotificationSocketService notificationSocketService;

  const DriverHomeScreen({
    super.key,
    required this.driverHomeController,
    required this.parentHomeController,
    required this.profileController,
    required this.authController,
    required this.themeController,
    required this.ticketController,
    required this.paymentController,
    required this.mapController,
    required this.leaveRequestController,
    required this.scheduleController,
    required this.driverScheduleController,
    required this.notificationController,
    required this.chatbotController,
    required this.fcmService,
    required this.dioClient,
    required this.socketService,
    required this.notificationSocketService,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentNavIndex = 0;
  int _previousNavIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.profileController.loadProfile();
    widget.driverHomeController.loadTodayTrips();
  }

  @override
  Widget build(BuildContext context) {
    final isForward = _currentNavIndex >= _previousNavIndex;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          final slideIn = Tween<Offset>(
            begin: Offset(isForward ? 1.0 : -1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ));

          return SlideTransition(
            position: slideIn,
            child: child,
          );
        },
        child: _buildCurrentTab(context),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _previousNavIndex = _currentNavIndex;
            _currentNavIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context) {
    switch (_currentNavIndex) {
      case 1:
        // Tab Bản đồ — DriverMapScreen
        return DriverMapScreen(
          key: const ValueKey('driver_map'),
          driverHomeController: widget.driverHomeController,
          socketService: widget.socketService,
        );
      case 2:
        return DriverScheduleScreen(
          key: const ValueKey('driver_schedule'),
          scheduleController: widget.driverScheduleController,
          driverHomeController: widget.driverHomeController,
          notificationController: widget.notificationController,
        );
      case 3:
        return DriverProfileScreen(
          key: const ValueKey('driver_profile'),
          controller: widget.profileController,
          authController: widget.authController,
          parentHomeController: widget.parentHomeController,
          driverHomeController: widget.driverHomeController,
          themeController: widget.themeController,
          ticketController: widget.ticketController,
          paymentController: widget.paymentController,
          mapController: widget.mapController,
          leaveRequestController: widget.leaveRequestController,
          scheduleController: widget.scheduleController,
          driverScheduleController: widget.driverScheduleController,
          notificationController: widget.notificationController,
          chatbotController: widget.chatbotController,
          fcmService: widget.fcmService,
          dioClient: widget.dioClient,
          socketService: widget.socketService,
          notificationSocketService: widget.notificationSocketService,
        );
      case 0:
      default:
        return ListenableBuilder(
          key: const ValueKey('driver_home'),
          listenable: Listenable.merge([
            widget.driverHomeController,
            widget.profileController,
          ]),
          builder: (context, _) {
            if (widget.driverHomeController.isLoading &&
                widget.driverHomeController.todayTrips.isEmpty) {
              return _buildLoadingIndicator(context);
            }
            return _buildHomeBody(context);
          },
        );
    }
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Body trang chủ — luôn là trạng thái Idle (State A).
  Widget _buildHomeBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = widget.driverHomeController;
    final nextTrip = ctrl.nextTrip;
    final activeTrip = ctrl.activeTrip;
    final remainingTrips = ctrl.remainingTrips;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ctrl.loadTodayTrips(),
        color: colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───
              DriverHeaderWidget(
                profile: ctrl.profile,
                greeting: ctrl.getGreeting(),
                notificationController: widget.notificationController,
                onAvatarTap: () => setState(() {
                  _previousNavIndex = _currentNavIndex;
                  _currentNavIndex = 3;
                }),
                onNotificationTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationScreen(
                      controller: widget.notificationController,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLG),

              // ─── Lời chào đặc biệt ───
              _buildMotivationBanner(context, isDark),
              const SizedBox(height: AppConstants.paddingLG),

              // ─── Quick Actions ───
              DriverQuickActionsWidget(
                onScanQR: () => _openTripAttendanceList(),
                onStationList: () => _openTripDetailForFirst(),
                onSupport: () => _openSupportScreen(),
                onHistory: () => _openHistoryScreen(),
              ),
              const SizedBox(height: AppConstants.paddingLG),

              // ─── Active trip banner (nếu đang chạy) ───
              if (activeTrip != null) ...[
                _buildActiveTripBanner(context, isDark),
                const SizedBox(height: AppConstants.paddingLG),
              ],

              // ─── Next Trip Card ───
              if (nextTrip != null) ...[
                Text(
                  'Chuyến tiếp theo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSM),
                DriverNextTripCardWidget(
                  trip: nextTrip,
                  isStarting: ctrl.isLoading,
                  onStartTrip: () => _handleStartTrip(nextTrip.id),
                ),
                const SizedBox(height: AppConstants.paddingLG),
              ],

              // ─── Empty state ───
              if (nextTrip == null && activeTrip == null)
                _buildEmptyState(context, isDark),

              // ─── Remaining trips ───
              DriverRemainingTripsWidget(
                trips: remainingTrips,
                onTripSelected: (trip) => _handleStartTrip(trip.id),
              ),
              const SizedBox(height: AppConstants.paddingLG),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner "Chúc một ngày lái xe an toàn!"
  Widget _buildMotivationBanner(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: 0.15),
            colorScheme.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lái xe an toàn!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chúc bác tài một ngày làm việc hiệu quả 🚌',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Banner nhỏ khi đang có chuyến active — bấm để chuyển tab bản đồ.
  Widget _buildActiveTripBanner(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeTrip = widget.driverHomeController.activeTrip;

    return GestureDetector(
      onTap: () => setState(() {
        _previousNavIndex = _currentNavIndex;
        _currentNavIndex = 1;
      }),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_bus_filled,
                color: AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đang có chuyến xe',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeTrip?.route?.name ?? 'Bấm để xem bản đồ',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Xem',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state khi không có chuyến nào hôm nay.
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.weekend_outlined,
              size: 40,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          Text(
            'Không có chuyến xe nào hôm nay',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn có thể nghỉ ngơi hoặc kiểm tra lịch trình ngày khác.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Bấm "BẮT ĐẦU CHUYẾN" → chuyển sang tab Bản đồ (preview, chưa gọi API).
  void _handleStartTrip(String tripId) {
    final ctrl = widget.driverHomeController;
    // Tìm chuyến theo ID từ danh sách hôm nay
    final trip = ctrl.todayTrips.cast<TripModel?>().firstWhere(
          (t) => t!.id == tripId,
          orElse: () => null,
        );
    if (trip == null) return;

    // Lưu chuyến vào pending → hiển thị preview trên map
    ctrl.setPendingTrip(trip);

    setState(() {
      _previousNavIndex = _currentNavIndex;
      _currentNavIndex = 1; // Chuyển sang tab Bản đồ
    });
  }

  /// Mở danh sách điểm danh toàn chuyến (từ nút Quét QR nhanh).
  void _openTripAttendanceList() {
    final ctrl = widget.driverHomeController;
    final trip = ctrl.activeTrip ?? ctrl.nextTrip;
    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có chuyến đi nào để xem điểm danh'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showTripAttendanceList(
      context: context,
      tripId: trip.id,
      tripName: trip.route?.name ?? 'Chuyến đi',
      controller: ctrl,
    );
  }

  /// Mở chi tiết chuyến đầu tiên (từ nút DS Chuyến).
  void _openTripDetailForFirst() {
    final allTrips = widget.driverHomeController.todayTrips;
    if (allTrips.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverTripDetailScreen(
          allTrips: allTrips,
          initialTripIndex: 0,
          controller: widget.driverHomeController,
        ),
      ),
    );
  }

  void _openSupportScreen() {
    final userId = widget.profileController.profile?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa tải được thông tin tài khoản'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final api = SupportTicketApi(widget.dioClient);
    final repo = ApiSupportRepository(api);
    final controller = SupportController(repo);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverSupportScreen(
          controller: controller,
          userId: userId,
        ),
      ),
    );
  }

  void _openHistoryScreen() {
    final repo = widget.driverHomeController.driverTripRepository;
    final controller = DriverHistoryController(repo);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverHistoryScreen(
          controller: controller,
          driverHomeController: widget.driverHomeController,
        ),
      ),
    );
  }
}
