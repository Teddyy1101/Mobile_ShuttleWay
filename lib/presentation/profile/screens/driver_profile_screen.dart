import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/fcm_service.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/network/notification_socket_service.dart';
import '../controllers/profile_controller.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/parent_home_controller.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../../home/controllers/leave_request_controller.dart';
import '../../home/controllers/schedule_controller.dart';
import '../../home/controllers/driver_schedule_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../ticket/controllers/ticket_controller.dart';
import '../../ticket/controllers/payment_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../home/controllers/chatbot_controller.dart';
import 'edit_profile_screen.dart';
import '../../home/screens/driver_stats_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  final ProfileController controller;
  final AuthController authController;
  final ParentHomeController parentHomeController;
  final DriverHomeController driverHomeController;
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

  const DriverProfileScreen({
    super.key,
    required this.controller,
    required this.authController,
    required this.parentHomeController,
    required this.driverHomeController,
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
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.95)
            : AppColors.lightBackground.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Cá nhân',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.grey[800]!.withValues(alpha: 0.5)
                : Colors.grey[200]!.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading &&
              widget.controller.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBody(context, theme, isDark);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C252E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(theme, isDark, cardColor),
          const SizedBox(height: 8),
          _buildDriverInfoSection(theme, isDark, cardColor),
          _buildSettingsSection(theme, isDark, cardColor, borderColor),
          _buildAccountSection(context, theme, isDark, cardColor, borderColor),
        ],
      ),
    );
  }

  /// Header: Avatar + Tên + Vai trò "Tài xế".
  Widget _buildProfileHeader(
    ThemeData theme,
    bool isDark,
    Color cardColor,
  ) {
    final profile = widget.controller.profile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32, bottom: 32),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1C252E) : Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null
                      ? Text(
                          profile?.fullName.isNotEmpty == true
                              ? profile!.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        controller: widget.controller,
                      ),
                    ),
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1C252E)
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile?.fullName ?? 'Tài xế',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tài xế',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Section: Thông tin tài xế — SĐT, email, số chuyến.
  Widget _buildDriverInfoSection(
    ThemeData theme,
    bool isDark,
    Color cardColor,
  ) {
    final profile = widget.controller.profile;
    final driverCtrl = widget.driverHomeController;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'THÔNG TIN TÀI XẾ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Email
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: profile?.email ?? 'N/A',
                  isDark: isDark,
                  showDivider: true,
                ),
                // Phone
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: profile?.phone ?? 'Chưa cập nhật',
                  isDark: isDark,
                  showDivider: true,
                ),
                // Trips today
                ListenableBuilder(
                  listenable: driverCtrl,
                  builder: (context, _) {
                    final total = driverCtrl.todayTrips.length;
                    final completed = driverCtrl.todayTrips
                        .where(
                            (t) => t.status.toUpperCase() == 'COMPLETED')
                        .length;
                    return _buildInfoRow(
                      icon: Icons.directions_bus_outlined,
                      label: 'Hôm nay: $completed/$total chuyến hoàn thành',
                      isDark: isDark,
                      showDivider: true,
                    );
                  },
                ),
                // Thống kê hoạt động
                _buildStatsRow(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Row bấm vào để mở màn hình Thống kê hoạt động.
  Widget _buildStatsRow(bool isDark) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverStatsScreen(
            driverTripRepository:
                widget.driverHomeController.driverTripRepository,
          ),
        ),
      ),
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Thống kê hoạt động',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required bool isDark,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark
                ? Colors.grey[800]!.withValues(alpha: 0.5)
                : Colors.grey[200],
          ),
      ],
    );
  }

  /// Section: Cài đặt — Dark mode toggle.
  Widget _buildSettingsSection(
    ThemeData theme,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'CÀI ĐẶT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ListenableBuilder(
              listenable: widget.themeController,
              builder: (context, _) {
                final isDarkNow = widget.themeController.isDark;
                return InkWell(
                  onTap: () => widget.themeController.toggleTheme(),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isDarkNow
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            size: 20,
                            color: Colors.indigo[400],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isDarkNow ? 'Chế độ tối' : 'Chế độ sáng',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: isDarkNow,
                            onChanged: (_) =>
                                widget.themeController.toggleTheme(),
                            activeColor: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Section: Tài khoản — đổi mật khẩu + đăng xuất.
  Widget _buildAccountSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'TÀI KHOẢN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Đăng xuất
                InkWell(
                  onTap: () => _handleLogout(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.red.withValues(alpha: 0.1)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'SHUTTLE WAY • VERSION 1.0.1',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isDark ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Logout flow — bottom sheet xác nhận.
  Future<void> _handleLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C252E) : Colors.white;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red
                        .withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_rounded,
                      color: Colors.red[600], size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Đăng xuất',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppConstants.radiusMD),
                      ),
                    ),
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.grey[400] : Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppConstants.radiusMD),
                        side: BorderSide(
                          color: isDark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await widget.controller.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              authController: widget.authController,
              parentHomeController: widget.parentHomeController,
              driverHomeController: widget.driverHomeController,
              profileController: widget.controller,
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
            ),
          ),
          (route) => false,
        );
      }
    }
  }
}
