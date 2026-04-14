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
import '../../../data/models/child_model.dart';
import '../../ticket/controllers/ticket_controller.dart';
import '../../ticket/controllers/payment_controller.dart';
import '../../home/controllers/parent_home_controller.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../../home/controllers/leave_request_controller.dart';
import '../../home/controllers/schedule_controller.dart';
import '../../home/controllers/driver_schedule_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../home/controllers/chatbot_controller.dart';
import 'edit_profile_screen.dart';
import 'parent_management_screen.dart';
import 'payment_history_screen.dart';
import 'ticket_management_screen.dart';
import '../../support/screens/support_screen.dart';
import '../../support/controllers/support_controller.dart';
import '../../../data/sources/support_ticket_api.dart';
import '../../../data/repositories/impl/api_support_repository.dart';

class StudentProfileScreen extends StatefulWidget {
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

  const StudentProfileScreen({
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
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _notifyBoardAlighting = true;

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
          _buildProfileHeader(theme, isDark, cardColor, borderColor),
          const SizedBox(height: 8),
          _buildLinkedParentsSection(theme, isDark, cardColor, borderColor),
          _buildSettingsSection(theme, isDark, cardColor, borderColor),
          _buildNotificationSection(theme, isDark, cardColor, borderColor),
          _buildAccountSection(context, theme, isDark, cardColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    ThemeData theme,
    bool isDark,
    Color cardColor,
    Color borderColor,
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
                        color: isDark ? const Color(0xFF1C252E) : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile?.fullName ?? 'Học sinh',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Học sinh',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Section: Phụ huynh liên kết — grid 2 cột.
  Widget _buildLinkedParentsSection(
    ThemeData theme,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    final parents = widget.controller.linkedUsers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PHỤ HUYNH LIÊN KẾT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentManagementScreen(
                          controller: widget.controller,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Quản lý',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (parents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Chưa liên kết phụ huynh nào',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: parents.length,
              itemBuilder: (context, index) {
                final parent = parents[index];
                return _buildLinkedUserCard(
                  theme, isDark, cardColor, borderColor,
                  name: parent.fullName,
                  subtitle: parent.email,
                  avatarUrl: parent.avatarUrl,
                  onTap: () => _showLinkedUserDetail(context, parent, false),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLinkedUserCard(
    ThemeData theme,
    bool isDark,
    Color cardColor,
    Color borderColor, {
    required String name,
    required String subtitle,
    String? avatarUrl,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              ),
            ),
            child: CircleAvatar(
              radius: 23,
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    )
    );
  }

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
              'CÀI ĐẶT CHUNG',
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
                _buildSettingRow(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.confirmation_number_outlined,
                  iconBgColor: Colors.green.withValues(alpha: 0.1),
                  iconColor: Colors.green[600]!,
                  label: 'Quản lý vé',
                  showDivider: true,
                  borderColor: borderColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketManagementScreen(
                          controller: widget.controller,
                        ),
                      ),
                    );
                  },
                ),
                _buildSettingRow(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.receipt_long_outlined,
                  iconBgColor: Colors.orange.withValues(alpha: 0.1),
                  iconColor: Colors.orange[600]!,
                  label: 'Lịch sử thanh toán',
                  showDivider: true,
                  borderColor: borderColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentHistoryScreen(
                          controller: widget.controller,
                        ),
                      ),
                    );
                  },
                ),
                _buildSettingRow(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.support_agent_rounded,
                  iconBgColor: Colors.teal.withValues(alpha: 0.1),
                  iconColor: Colors.teal[600]!,
                  label: 'Hỗ trợ',
                  showDivider: true,
                  borderColor: borderColor,
                  onTap: () => _openSupportScreen(),
                ),
                // ── Toggle Dark / Light ──
                ListenableBuilder(
                  listenable: widget.themeController,
                  builder: (context, _) {
                    final isDarkNow = widget.themeController.isDark;
                    return InkWell(
                      onTap: () => widget.themeController.toggleTheme(),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(
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
              'THÔNG BÁO',
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      size: 20,
                      color: Colors.purple[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông báo lên/xuống xe',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nhận thông báo khi xe đến trạm',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _notifyBoardAlighting,
                      onChanged: (v) => setState(() => _notifyBoardAlighting = v),
                      activeColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                _buildSettingRow(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.lock_reset_outlined,
                  iconBgColor: Colors.grey.withValues(alpha: 0.1),
                  iconColor: isDark ? Colors.grey[300]! : Colors.grey[600]!,
                  label: 'Đổi mật khẩu',
                  showDivider: true,
                  borderColor: borderColor,
                  onTap: () => _showChangePasswordDialog(context),
                ),
                InkWell(
                  onTap: () => _handleLogout(context),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
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
              'BUS SAFE APP • VERSION 1.0.1',
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

  Widget _buildSettingRow({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required bool showDivider,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
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
                Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark ? Colors.grey[800]!.withValues(alpha: 0.5) : Colors.grey[200],
          ),
      ],
    );
  }

  // ─── Support ────────────────────────────────────────────────────

  void _openSupportScreen() {
    final userId = widget.controller.profile?.id;
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
        builder: (_) => SupportScreen(
          controller: controller,
          userId: userId,
        ),
      ),
    );
  }

  // ─── Dialogs ────────────────────────────────────────────────────

  /// Bottom sheet thông tin chi tiết người liên kết
  void _showLinkedUserDetail(BuildContext context, ChildModel user, bool isStudent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C252E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 37,
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  user.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isActive ? const Color(0xFF22C55E).withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.isActive ? 'Đang hoạt động' : 'Ngừng hoạt động',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: user.isActive ? const Color(0xFF22C55E) : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Detail rows
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user.email,
                ),
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.phone_outlined,
                  label: 'Số điện thoại',
                  value: user.phone ?? 'Chưa cập nhật',
                  isLast: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark ? Colors.grey[800]!.withValues(alpha: 0.5) : Colors.grey[200],
          ),
      ],
    );
  }

  /// Bottom sheet đổi mật khẩu.
  void _showChangePasswordDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final oldPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final sheetBg = isDark ? const Color(0xFF1C252E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24, 16, 24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Đổi mật khẩu', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Nhập mật khẩu cũ và mật khẩu mới để thay đổi',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: _PasswordFields(oldPwCtrl: oldPwCtrl, newPwCtrl: newPwCtrl, isDark: isDark, theme: theme),
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: AppConstants.buttonHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.controller.isChangingPassword
                                  ? [Colors.grey, Colors.grey]
                                  : [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                            ),
                            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                            boxShadow: widget.controller.isChangingPassword ? [] : [
                              BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: widget.controller.isChangingPassword ? null : () async {
                              if (!formKey.currentState!.validate()) return;
                              final success = await widget.controller.changePassword(oldPwCtrl.text.trim(), newPwCtrl.text.trim());
                              if (ctx.mounted && success) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Đổi mật khẩu thành công'),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                            ),
                            child: widget.controller.isChangingPassword
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : const Text('Xác nhận', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: AppConstants.buttonHeight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                              side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            ),
                          ),
                          child: const Text('Hủy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_rounded, color: Colors.red[600], size: 28),
                ),
                const SizedBox(height: 16),
                Text('Đăng xuất', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[500]),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                    ),
                    child: const Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                        side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      ),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
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

/// Widget password fields với toggle show/hide.
class _PasswordFields extends StatefulWidget {
  final TextEditingController oldPwCtrl;
  final TextEditingController newPwCtrl;
  final bool isDark;
  final ThemeData theme;

  const _PasswordFields({
    required this.oldPwCtrl,
    required this.newPwCtrl,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_PasswordFields> createState() => _PasswordFieldsState();
}

class _PasswordFieldsState extends State<_PasswordFields> {
  bool _showOldPw = false;
  bool _showNewPw = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: widget.oldPwCtrl,
          obscureText: !_showOldPw,
          decoration: InputDecoration(
            labelText: 'Mật khẩu cũ',
            prefixIcon: Icon(Icons.lock_outline, color: widget.isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
            suffixIcon: IconButton(
              icon: Icon(_showOldPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: widget.isDark ? Colors.grey[400] : Colors.grey[500], size: 20),
              onPressed: () => setState(() => _showOldPw = !_showOldPw),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(color: widget.theme.colorScheme.primary, width: 1.5),
            ),
            filled: true,
            fillColor: widget.isDark ? Colors.grey[900]!.withValues(alpha: 0.3) : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu cũ' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.newPwCtrl,
          obscureText: !_showNewPw,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            prefixIcon: Icon(Icons.lock_reset_outlined, color: widget.isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
            suffixIcon: IconButton(
              icon: Icon(_showNewPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: widget.isDark ? Colors.grey[400] : Colors.grey[500], size: 20),
              onPressed: () => setState(() => _showNewPw = !_showNewPw),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(color: widget.theme.colorScheme.primary, width: 1.5),
            ),
            filled: true,
            fillColor: widget.isDark ? Colors.grey[900]!.withValues(alpha: 0.3) : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
            if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
            return null;
          },
        ),
      ],
    );
  }
}

