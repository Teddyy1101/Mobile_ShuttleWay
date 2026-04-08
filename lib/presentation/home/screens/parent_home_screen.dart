import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../data/models/ticket_model.dart';
import '../controllers/parent_home_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../map/screens/map_screen.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/screens/parent_profile_screen.dart';
import '../../profile/screens/student_profile_screen.dart';
import '../../ticket/controllers/ticket_controller.dart';
import '../../ticket/controllers/payment_controller.dart';
import '../controllers/leave_request_controller.dart';
import '../controllers/schedule_controller.dart';
import 'schedule_screen.dart';
import '../../ticket/screens/parent_book_ticket_screen.dart';
import '../../ticket/screens/student_book_ticket_screen.dart';

import '../widgets/student_card_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/bus_map_widget.dart';
import '../widgets/recent_activities_widget.dart';
import '../widgets/bottom_nav_bar_widget.dart';
import 'ticket_history_screen.dart';

/// Trang chủ chung cho cả phụ huynh và học sinh.
class ParentHomeScreen extends StatefulWidget {
  final ParentHomeController controller;
  final ProfileController profileController;
  final AuthController authController;
  final ThemeController themeController;
  final TicketController ticketController;
  final PaymentController paymentController;
  final MapController mapController;
  final LeaveRequestController leaveRequestController;
  final ScheduleController scheduleController;

  const ParentHomeScreen({
    super.key,
    required this.controller,
    required this.profileController,
    required this.authController,
    required this.themeController,
    required this.ticketController,
    required this.paymentController,
    required this.mapController,
    required this.leaveRequestController,
    required this.scheduleController,
  });

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  int _previousNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load dữ liệu chung
    widget.profileController.loadProfile();
    widget.controller.loadData();
    // Nếu là STUDENT → load vé để hiển thị trên home
    if (!widget.profileController.isParent) {
      widget.profileController.loadMyTickets(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chiều slide: tab cao hơn → trượt từ phải, tab thấp hơn → trượt từ trái
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

  /// Chọn nội dung theo tab hiện tại.
  /// Mỗi tab trả về widget với ValueKey khác nhau để AnimatedSwitcher hoạt động.
  Widget _buildCurrentTab(BuildContext context) {
    switch (_currentNavIndex) {
      case 1:
        return MapScreen(
          key: const ValueKey('map'),
          mapController: widget.mapController,
        );
      case 2:
        return ScheduleScreen(
          key: const ValueKey('schedule'),
          scheduleController: widget.scheduleController,
          profileController: widget.profileController,
          leaveRequestController: widget.leaveRequestController,
        );
      case 3:
        if (widget.profileController.isParent) {
          return ParentProfileScreen(
            key: const ValueKey('parent_profile'),
            controller: widget.profileController,
            authController: widget.authController,
            parentHomeController: widget.controller,
            themeController: widget.themeController,
            ticketController: widget.ticketController,
            paymentController: widget.paymentController,
            mapController: widget.mapController,
            leaveRequestController: widget.leaveRequestController,
            scheduleController: widget.scheduleController,
          );
        } else {
          return StudentProfileScreen(
            key: const ValueKey('student_profile'),
            controller: widget.profileController,
            authController: widget.authController,
            parentHomeController: widget.controller,
            themeController: widget.themeController,
            ticketController: widget.ticketController,
            paymentController: widget.paymentController,
            mapController: widget.mapController,
            leaveRequestController: widget.leaveRequestController,
            scheduleController: widget.scheduleController,
          );
        }
      case 0:
      default:
        if (widget.profileController.isParent) {
          return ListenableBuilder(
            key: const ValueKey('parent_home'),
            listenable: Listenable.merge([
              widget.controller,
              widget.profileController,
            ]),
            builder: (context, _) {
              final isDataLoading = widget.controller.isLoading &&
                  widget.controller.profile == null;
              final isChildrenLoading =
                  widget.profileController.isLoading &&
                      widget.profileController.linkedUsers.isEmpty;

              if (isDataLoading || isChildrenLoading) {
                return _buildLoadingIndicator(context);
              }
              return _buildParentBody(context);
            },
          );
        } else {
          return ListenableBuilder(
            key: const ValueKey('student_home'),
            listenable: widget.profileController,
            builder: (context, _) {
              if (widget.profileController.isLoading &&
                  widget.profileController.profile == null) {
                return _buildLoadingIndicator(context);
              }
              return _buildStudentBody(context);
            },
          );
        }
    }
  }

  /// Loading indicator toàn màn hình khi đang tải dữ liệu.
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

  // PARENT 

  Widget _buildParentBody(BuildContext context) {
    final controller = widget.controller;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingMD),
              _buildHeader(context, controller),
              const SizedBox(height: AppConstants.paddingLG),
              Text(
                'Trạng thái của bé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSM),
              StudentCardWidget(
                children: controller.children,
                isLoading: controller.isLoading,
                errorMessage: controller.errorMessage,
                onLinkStudent: controller.linkStudent,
              ),
              const SizedBox(height: AppConstants.paddingLG),
              QuickActionsWidget(
                onBookTicket: () => _navigateToBookTicket(),
                onHistory: () => _navigateToTicketHistory(),
              ),
              const SizedBox(height: AppConstants.paddingLG),
              BusMapWidget(
                onExpandMap: () {
                  setState(() {
                    _previousNavIndex = _currentNavIndex;
                    _currentNavIndex = 1;
                  });
                },
              ),
              const SizedBox(height: AppConstants.paddingLG),
              RecentActivitiesWidget(
                activities: controller.recentActivities,
              ),
              const SizedBox(height: AppConstants.paddingMD),
            ],
          ),
        ),
      ),
    );
  }

  // STUDENT 

  Widget _buildStudentBody(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = widget.profileController.profile;
    final tickets = widget.profileController.tickets;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => widget.profileController.loadMyTickets(refresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingMD),
              // ─── Header ───
              _buildStudentHeader(context, profile, isDark),
              const SizedBox(height: AppConstants.paddingLG),
              // ─── Chuyến đi / Vé hiện tại ───
              Text(
                'Chuyến đi của bạn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSM),
              _buildActiveTicketCard(context, tickets, theme, isDark),
              const SizedBox(height: AppConstants.paddingLG),
              // ─── Quick Actions ───
              QuickActionsWidget(
                onBookTicket: () => _navigateToBookTicket(),
                onHistory: () => _navigateToTicketHistory(),
              ),
              const SizedBox(height: AppConstants.paddingLG),
              // ─── Bus Map ───
              BusMapWidget(
                onExpandMap: () {
                  setState(() {
                    _previousNavIndex = _currentNavIndex;
                    _currentNavIndex = 1;
                  });
                },
              ),
              const SizedBox(height: AppConstants.paddingLG),
              // ─── Recent Activities ───
              RecentActivitiesWidget(
                activities: widget.controller.recentActivities,
              ),
              const SizedBox(height: AppConstants.paddingMD),
            ],
          ),
        ),
      ),
    );
  }

  /// Điều hướng đến màn hình lịch sử vé.
  void _navigateToTicketHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketHistoryScreen(
          profileController: widget.profileController,
          children: widget.controller.children,
        ),
      ),
    );
  }

  /// Header cho học sinh: avatar + greeting + name.
  Widget _buildStudentHeader(
      BuildContext context, dynamic profile, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _currentNavIndex = 3),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.success, colorScheme.primary],
              ),
            ),
            child: CircleAvatar(
              radius: AppConstants.avatarSizeSM / 2,
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              backgroundImage: profile?.avatarUrl != null
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: profile?.avatarUrl == null
                  ? Text(
                      profile?.fullName.isNotEmpty == true
                          ? profile!.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.controller.getGreeting(),
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile?.fullName ?? 'Học sinh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Stack(
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
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_none_rounded,
                  size: AppConstants.iconSizeSM,
                  color: colorScheme.onSurface,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
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
        ),
      ],
    );
  }

  /// Card hiển thị vé đang hoạt động hoặc trạng thái không có vé.
  Widget _buildActiveTicketCard(
    BuildContext context,
    List<TicketModel> tickets,
    ThemeData theme,
    bool isDark,
  ) {
    // Tìm vé ACTIVE đầu tiên
    final activeTicket = tickets.cast<TicketModel?>().firstWhere(
          (t) => t?.status.toUpperCase() == 'ACTIVE',
          orElse: () => null,
        );

    if (activeTicket == null) {
      // Không có vé active → show CTA mua vé
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C252E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 40,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn chưa có vé đang hoạt động',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mua vé để sử dụng xe buýt',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToBookTicket,
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                label: const Text('Đặt vé ngay'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Có vé active → show card chuyến đi
    final routeName = activeTicket.route?.name ?? 'N/A';
    final isMonthly = activeTicket.ticketType == 'MONTHLY';
    final validUntil = DateFormat('dd/MM/yyyy')
        .format(activeTicket.validUntil.toLocal());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                // Xe đang đến label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isMonthly ? 'Vé tháng' : 'Vé lượt',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'HSD: $validUntil',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Route name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_bus_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getShiftLabel(activeTicket.route?.shiftType),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // QR button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Mở màn hình quét QR điểm danh
              },
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text('Xem mã QR để điểm danh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header với avatar, lời chào và tên phụ huynh.
  Widget _buildHeader(BuildContext context, ParentHomeController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = controller.profile;

    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _currentNavIndex = 3),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.success,
                  colorScheme.primary,
                ],
              ),
            ),
            child: CircleAvatar(
              radius: AppConstants.avatarSizeSM / 2,
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              backgroundImage: profile?.avatarUrl != null
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: profile?.avatarUrl == null
                  ? Text(
                      profile?.fullName.isNotEmpty == true
                          ? profile!.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.getGreeting(),
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile?.fullName ?? 'Phụ huynh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Stack(
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
                  // TODO: Navigate to notifications
                },
                icon: Icon(
                  Icons.notifications_none_rounded,
                  size: AppConstants.iconSizeSM,
                  color: colorScheme.onSurface,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
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
        ),
      ],
    );
  }

  // Helpers

  void _navigateToBookTicket() {
    final isParent = widget.profileController.isParent;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isParent
            ? ParentBookTicketScreen(
                ticketController: widget.ticketController,
                profileController: widget.profileController,
                paymentController: widget.paymentController,
              )
            : StudentBookTicketScreen(
                ticketController: widget.ticketController,
                profileController: widget.profileController,
                paymentController: widget.paymentController,
              ),
      ),
    );
  }

  String _getShiftLabel(String? shiftType) {
    switch (shiftType?.toUpperCase()) {
      case 'MORNING':
        return 'Ca sáng';
      case 'AFTERNOON':
        return 'Ca chiều';
      case 'BOTH':
        return 'Cả ngày';
      default:
        return 'N/A';
    }
  }
}

