import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/route_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/ticket_controller.dart';
import '../controllers/payment_controller.dart';
import 'payment_screen.dart';

/// Màn hình đặt vé xe buýt dành cho Phụ huynh.
/// Giao diện 1:1 từ HTML mockup.
class ParentBookTicketScreen extends StatefulWidget {
  final TicketController ticketController;
  final ProfileController profileController;
  final PaymentController paymentController;

  const ParentBookTicketScreen({
    super.key,
    required this.ticketController,
    required this.profileController,
    required this.paymentController,
  });

  @override
  State<ParentBookTicketScreen> createState() => _ParentBookTicketScreenState();
}

class _ParentBookTicketScreenState extends State<ParentBookTicketScreen> {
  int _selectedDateIndex = 0;
  DateTime? _customPickedDate;

  @override
  void initState() {
    super.initState();
    widget.ticketController.loadRoutes();
    // Load danh sách học sinh nếu chưa có
    if (widget.profileController.linkedUsers.isEmpty) {
      widget.profileController.loadProfile().then((_) {
        _autoSelectFirstChild();
      });
    } else {
      _autoSelectFirstChild();
    }
  }

  /// Tự động chọn học sinh đầu tiên nếu chưa chọn.
  void _autoSelectFirstChild() {
    final children = widget.profileController.linkedUsers;
    if (children.isNotEmpty && widget.ticketController.selectedChild == null) {
      widget.ticketController.selectChild(children.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.ticketController,
          widget.profileController,
        ]),
        builder: (context, _) {
          final isChildrenLoading = widget.profileController.isLoading &&
              widget.profileController.linkedUsers.isEmpty;

          return Column(
            children: [
              // ── App Bar ──
              _buildAppBar(theme, isDark, backgroundColor),
              // ── Content ──
              Expanded(
                child: (widget.ticketController.isLoading || isChildrenLoading)
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.paddingLG,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildChildSelector(theme, isDark),
                            _buildTicketTypeSelector(theme, isDark),
                            _buildRouteSection(theme, isDark),
                            _buildDateSelector(theme, isDark),
                            _buildSummaryCard(theme, isDark),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────

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
                'Đặt vé xe buýt',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Spacer cho cân bằng layout
            const SizedBox(width: AppConstants.avatarSizeMD),
          ],
        ),
      ),
    );
  }

  // ─── Chọn học sinh ──────────────────────────────────────────

  Widget _buildChildSelector(ThemeData theme, bool isDark) {
    final children = widget.profileController.linkedUsers;
    final selectedChild = widget.ticketController.selectedChild;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Chọn học sinh'),
          const SizedBox(height: AppConstants.paddingSM + 4),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: children.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppConstants.paddingSM + 4),
              itemBuilder: (context, index) {
                final child = children[index];
                final isSelected = selectedChild?.id == child.id;
                return _buildChildChip(child, isSelected, theme, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildChip(
      ChildModel child, bool isSelected, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => widget.ticketController.selectChild(child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingSM,
          vertical: AppConstants.paddingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.darkCard : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: AppConstants.iconSizeSM,
              backgroundColor: isSelected
                  ? AppColors.darkTextPrimary.withValues(alpha: 0.3)
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.darkTextPrimary
                            : theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppConstants.paddingSM),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.darkTextPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  child.email,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? AppColors.darkTextPrimary.withValues(alpha: 0.8)
                        : (isDark
                            ? AppColors.darkTextHint
                            : AppColors.lightTextHint),
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: AppConstants.paddingSM),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.darkTextPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Loại vé ──────────────────────────────────────────────

  Widget _buildTicketTypeSelector(ThemeData theme, bool isDark) {
    final selectedType = widget.ticketController.selectedTicketType;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingLG,
        AppConstants.paddingMD,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Loại vé'),
          const SizedBox(height: AppConstants.paddingSM + 4),
          Row(
            children: [
              Expanded(
                child: _buildTicketTypeCard(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Theo lượt',
                  isSelected: selectedType == 'SINGLE_TRIP',
                  onTap: () => widget.ticketController
                      .selectTicketType('SINGLE_TRIP'),
                  theme: theme,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppConstants.paddingSM + 4),
              Expanded(
                child: _buildTicketTypeCard(
                  icon: Icons.calendar_view_month_rounded,
                  label: 'Theo tháng',
                  isSelected: selectedType == 'MONTHLY',
                  onTap: () =>
                      widget.ticketController.selectTicketType('MONTHLY'),
                  theme: theme,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppConstants.paddingSM + 4),
              Expanded(
                child: _buildTicketTypeCard(
                  icon: Icons.school_outlined,
                  label: 'Theo kỳ',
                  isSelected: false,
                  onTap: () => AppToast.showError(
                    context,
                    'Tính năng đang phát triển',
                  ),
                  theme: theme,
                  isDark: isDark,
                  isDisabled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketTypeCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
    required ThemeData theme,
    required bool isDark,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMD),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: isDisabled ? 0.4 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: AppConstants.iconSizeMD,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint),
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: AppConstants.paddingSM,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Lộ trình ──────────────────────────────────────────────

  Widget _buildRouteSection(ThemeData theme, bool isDark) {
    final routes = widget.ticketController.routes;
    final selectedRoute = widget.ticketController.selectedRoute;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingLG,
        AppConstants.paddingMD,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Lộ trình'),
          const SizedBox(height: AppConstants.paddingSM + 4),
          // Route dropdown
          _buildRouteDropdown(routes, selectedRoute, theme, isDark),
          if (selectedRoute != null) ...[
            const SizedBox(height: AppConstants.paddingMD),
            // Route detail card
            _buildRouteDetailCard(selectedRoute, theme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteDropdown(
    List<RouteModel> routes,
    RouteModel? selectedRoute,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _showRouteSelector(routes, theme, isDark),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingSM + 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: AppConstants.avatarSizeSM,
              height: AppConstants.avatarSizeSM,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                selectedRoute?.routeCode ?? '--',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFEA580C),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.paddingSM + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedRoute != null
                        ? '${selectedRoute.routeCode}: ${selectedRoute.name}'
                        : 'Chọn tuyến đường',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (selectedRoute != null)
                    Text(
                      'Ca ${_getShiftLabel(selectedRoute.shiftType)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.lightTextHint,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more,
              color: isDark
                  ? AppColors.darkTextHint
                  : AppColors.lightTextHint,
            ),
          ],
        ),
      ),
    );
  }

  void _showRouteSelector(
      List<RouteModel> routes, ThemeData theme, bool isDark) {
    final sheetBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL - 4),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                // State tìm kiếm nội bộ BottomSheet
                return _RouteSearchSheet(
                  routes: routes,
                  theme: theme,
                  isDark: isDark,
                  scrollController: scrollController,
                  selectedRouteId: widget.ticketController.selectedRoute?.id,
                  onSelect: (route) {
                    widget.ticketController.selectRoute(route);
                    Navigator.pop(ctx);
                  },
                  getShiftLabel: _getShiftLabel,
                  formatCurrency: _formatCurrency,
                );
              },
            );
          },
        );
      },
    );
  }


  Widget _buildRouteDetailCard(
      RouteModel route, ThemeData theme, bool isDark) {
    final selected = widget.ticketController.selectedStation;
    final lastStation = route.lastStation;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD + 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
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
      child: Stack(
        children: [
          // Dashed line
          Positioned(
            left: 7.5,
            top: 36,
            bottom: 16,
            child: CustomPaint(
              size: const Size(2, double.infinity),
              painter: _DashedLinePainter(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
          Column(
            children: [
              // Điểm đón (chọn được)
              _buildStopRow(
                label: 'Điểm đón',
                stationName: selected?.station.name ?? 'Chọn điểm đón',
                timeLabel: route.formattedStartTime ?? '--:--',
                dotColor: theme.colorScheme.primary,
                showEdit: true,
                onTap: () => _showStationPicker(
                  title: 'Chọn điểm đón',
                  stations: widget.ticketController.selectableStations,
                  selectedStation: selected,
                  onSelect: widget.ticketController.selectStation,
                  theme: theme,
                  isDark: isDark,
                ),
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(height: AppConstants.paddingLG),
              // Điểm trả (cố định = trường học)
              _buildStopRow(
                label: 'Điểm trả (Trường học)',
                stationName: lastStation?.name ?? 'Trường học',
                timeLabel: route.formattedEndTime != null
                    ? '${route.formattedEndTime} (Dự kiến)'
                    : '-- (Dự kiến)',
                dotColor: AppColors.error,
                showEdit: false,
                theme: theme,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Hiển thị BottomSheet chọn trạm đón.
  void _showStationPicker({
    required String title,
    required List<RouteStationModel> stations,
    required RouteStationModel? selectedStation,
    required void Function(RouteStationModel) onSelect,
    required ThemeData theme,
    required bool isDark,
  }) {
    final sheetBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL - 4),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMD,
              AppConstants.paddingMD,
              AppConstants.paddingMD,
              AppConstants.paddingLG,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMD),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSM),
                if (stations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.paddingMD),
                    child: Center(
                      child: Text(
                        'Không có trạm hợp lệ',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                        ),
                      ),
                    ),
                  )
                else
                  ...stations.map((routeStation) {
                    final isSelected =
                        selectedStation?.station.id == routeStation.station.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.15)
                              : (isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightBorder
                                      .withValues(alpha: 0.3)),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${routeStation.orderIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      title: Text(
                        routeStation.station.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        onSelect(routeStation);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStopRow({
    required String label,
    required String stationName,
    required String timeLabel,
    required Color dotColor,
    required bool showEdit,
    required ThemeData theme,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSM,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: dotColor == theme.colorScheme.primary
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: dotColor == theme.colorScheme.primary
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: dotColor == theme.colorScheme.primary
                          ? theme.colorScheme.primary
                          : (isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Row(
            children: [
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: 4),
                  color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.paddingSM + 4),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(bottom: AppConstants.paddingSM),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: showEdit
                          ? BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          stationName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showEdit)
                        Icon(
                          Icons.expand_more,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Ngày khởi hành

  Widget _buildDateSelector(ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final dates = List.generate(4, (i) => now.add(Duration(days: i)));
    final dayLabels = ['Hôm nay', 'Ngày mai'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingLG + 8,
        AppConstants.paddingMD,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Ngày khởi hành'),
          const SizedBox(height: AppConstants.paddingSM + 4),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppConstants.paddingSM + 4),
              itemBuilder: (context, index) {
                if (index == dates.length) {
                  return _buildCustomDateButton(theme, isDark);
                }
                final date = dates[index];
                final isSelected = _selectedDateIndex == index;
                final topLabel = index < dayLabels.length
                    ? dayLabels[index]
                    : DateFormat('EEEE', 'vi').format(date);
                return _buildDateCard(
                  topLabel: topLabel,
                  day: date.day.toString(),
                  bottomLabel: _getWeekdayShort(date),
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedDateIndex = index;
                      _customPickedDate = null;
                    });
                    widget.ticketController.selectDate(date);
                  },
                  theme: theme,
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String topLabel,
    required String day,
    required String bottomLabel,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSM + 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.darkCard : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              topLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.darkTextPrimary.withValues(alpha: 0.8)
                    : (isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              day,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.darkTextPrimary
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              bottomLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.darkTextPrimary.withValues(alpha: 0.8)
                    : (isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDateButton(ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final presetCount = 4;
    final isCustomSelected =
        _customPickedDate != null && _selectedDateIndex == presetCount;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _customPickedDate ??
              now.add(const Duration(days: 1)),
          firstDate: now,
          lastDate: now.add(const Duration(days: 90)),
        );
        if (picked != null) {
          setState(() {
            _customPickedDate = picked;
            _selectedDateIndex = presetCount;
          });
          widget.ticketController.selectDate(picked);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSM + 4),
        decoration: BoxDecoration(
          color: isCustomSelected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: isCustomSelected
              ? Border.all(color: theme.colorScheme.primary)
              : null,
          boxShadow: isCustomSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isCustomSelected
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEEE', 'vi').format(_customPickedDate!),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextPrimary.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _customPickedDate!.day.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getWeekdayShort(_customPickedDate!),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_calendar,
                    size: AppConstants.iconSizeMD,
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    'Chọn',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Summary Card

  Widget _buildSummaryCard(ThemeData theme, bool isDark) {
    final selectedRoute = widget.ticketController.selectedRoute;
    final price = widget.ticketController.currentPrice;
    final isBuying = widget.ticketController.isBuying;
    final errorMessage = widget.ticketController.errorMessage;

    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final labelColor = isDark
        ? AppColors.darkTextHint
        : AppColors.lightTextHint;
    final priceColor = isDark
        ? AppColors.darkTextPrimary
        : theme.colorScheme.onSurface;
    final badgeBg = isDark
        ? AppColors.darkTextPrimary.withValues(alpha: 0.1)
        : theme.colorScheme.primary.withValues(alpha: 0.1);
    final badgeTextColor = isDark
        ? AppColors.darkTextPrimary
        : theme.colorScheme.primary;
    final dividerColor = isDark
        ? AppColors.darkTextPrimary.withValues(alpha: 0.1)
        : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingLG + 8,
        AppConstants.paddingMD,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMD + 4),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Price + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng chi phí',
                      style: TextStyle(
                        fontSize: 13,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _formatCurrency(price),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: priceColor,
                            ),
                          ),
                          TextSpan(
                            text: 'đ',
                            style: TextStyle(
                              fontSize: 16,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSM + 4,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                    border: Border.all(
                      color: badgeTextColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    'Thanh toán ngay',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),

            // Divider
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppConstants.paddingMD),
              child: Divider(height: 1, color: dividerColor),
            ),

            // Route info row
            if (selectedRoute != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.paddingMD + 4),
                child: Wrap(
                  spacing: AppConstants.paddingMD,
                  runSpacing: AppConstants.paddingSM,
                  children: [
                    _buildInfoChip(
                      icon: Icons.directions_bus_outlined,
                      text: selectedRoute.routeCode,
                      theme: theme,
                      isDark: isDark,
                    ),

                    _buildInfoChip(
                      icon: Icons.route_outlined,
                      text: selectedRoute.totalDistance != null
                          ? '${selectedRoute.totalDistance} km'
                          : 'N/A',
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildInfoChip(
                      icon: Icons.timer_outlined,
                      text: selectedRoute.totalDuration != null
                          ? '~${selectedRoute.totalDuration} phút'
                          : 'N/A',
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildInfoChip(
                      icon: Icons.schedule,
                      text: 'Ca ${_getShiftLabel(selectedRoute.shiftType)}',
                      theme: theme,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

            // Error message
            if (errorMessage != null)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: AppConstants.paddingSM),
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBuying ? null : _handleBuyTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.paddingMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMD),
                  ),
                  elevation: 0,
                  shadowColor:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: isBuying
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Xác nhận đặt vé',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: AppConstants.paddingSM),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppConstants.paddingXS),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  // Actions

  Future<void> _handleBuyTicket() async {
    final selectedChild = widget.ticketController.selectedChild;
    if (selectedChild == null) {
      AppToast.showError(context, 'Vui lòng chọn học sinh');
      return;
    }

    final ticket = await widget.ticketController.buyTicket(
      studentId: selectedChild.id,
    );

    if (ticket != null && mounted) {
      // Refresh danh sách vé ngầm
      widget.profileController.loadMyTickets(refresh: true);
      
      // Chuyển sang màn hình thanh toán
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            ticket: ticket,
            paymentController: widget.paymentController,
          ),
        ),
      );
    } else if (mounted && widget.ticketController.errorMessage != null) {
      AppToast.showError(context, widget.ticketController.errorMessage!);
    }
  }

  // Helpers

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
      ),
    );
  }

  String _getShiftLabel(String? shiftType) {
    switch (shiftType?.toUpperCase()) {
      case 'MORNING':
        return 'sáng';
      case 'AFTERNOON':
        return 'chiều';
      case 'BOTH':
        return 'cả ngày';
      default:
        return 'N/A';
    }
  }

  String _getWeekdayShort(DateTime date) {
    const days = ['CN', 'Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7'];
    return days[date.weekday % 7];
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount.abs());
  }
}

/// Custom painter cho đường nét đứt dọc (dashed vertical line).
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const gapHeight = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget tìm kiếm tuyến đường — dùng chung cho BottomSheet chọn tuyến.
class _RouteSearchSheet extends StatefulWidget {
  final List<RouteModel> routes;
  final ThemeData theme;
  final bool isDark;
  final ScrollController scrollController;
  final String? selectedRouteId;
  final void Function(RouteModel) onSelect;
  final String Function(String?) getShiftLabel;
  final String Function(double) formatCurrency;

  const _RouteSearchSheet({
    required this.routes,
    required this.theme,
    required this.isDark,
    required this.scrollController,
    required this.selectedRouteId,
    required this.onSelect,
    required this.getShiftLabel,
    required this.formatCurrency,
  });

  @override
  State<_RouteSearchSheet> createState() => _RouteSearchSheetState();
}

class _RouteSearchSheetState extends State<_RouteSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<RouteModel> get _filteredRoutes {
    if (_searchQuery.isEmpty) return widget.routes;
    final query = _searchQuery.toLowerCase();
    return widget.routes.where((route) {
      return route.routeCode.toLowerCase().contains(query) ||
          route.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRoutes;

    return SafeArea(
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.paddingMD),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Tiêu đề
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMD,
              AppConstants.paddingMD,
              AppConstants.paddingMD,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chọn tuyến đường',
                style: widget.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMD,
              AppConstants.paddingSM + 4,
              AppConstants.paddingMD,
              AppConstants.paddingSM,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã hoặc tên tuyến...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: widget.isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: widget.isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: widget.isDark
                    ? AppColors.darkCard
                    : AppColors.lightCard,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMD),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMD,
                  vertical: AppConstants.paddingSM + 4,
                ),
              ),
            ),
          ),
          // Danh sách
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: widget.isDark
                              ? Colors.grey[700]
                              : Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Không tìm thấy tuyến đường',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMD,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final route = filtered[index];
                      final isSelected =
                          widget.selectedRouteId == route.id;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: AppConstants.avatarSizeSM,
                          height: AppConstants.avatarSizeSM,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.theme.colorScheme.primary
                                    .withValues(alpha: 0.15)
                                : AppColors.warning
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusSM),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            route.routeCode,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? widget.theme.colorScheme.primary
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                        title: Text(
                          '${route.routeCode}: ${route.name}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? widget.theme.colorScheme.primary
                                : widget.theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Ca ${widget.getShiftLabel(route.shiftType)} • ${widget.formatCurrency(route.singlePrice)}đ/lượt',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: widget.theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () => widget.onSelect(route),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
