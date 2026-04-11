import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_card_widget.dart';
import '../widgets/notification_detail_bottom_sheet.dart';

/// Màn hình danh sách thông báo.
/// Hiển thị thông báo phân nhóm theo ngày (Hôm nay / Hôm qua / Cũ hơn).
class NotificationScreen extends StatefulWidget {
  final NotificationController controller;
  final VoidCallback? onViewTicket;

  const NotificationScreen({
    super.key,
    required this.controller,
    this.onViewTicket,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.loadNotifications(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Infinite scroll: load thêm khi cuộn gần cuối.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header sticky 
            _buildHeader(context, colorScheme, isDark),
            // Body 
            Expanded(
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  if (widget.controller.isLoading &&
                      widget.controller.notifications.isEmpty) {
                    return _buildLoadingIndicator(colorScheme);
                  }

                  if (widget.controller.errorMessage != null &&
                      widget.controller.notifications.isEmpty) {
                    return _buildErrorState(
                      colorScheme,
                      isDark,
                      widget.controller.errorMessage!,
                    );
                  }

                  if (widget.controller.notifications.isEmpty) {
                    return _buildEmptyState(colorScheme, isDark);
                  }

                  return _buildNotificationList(colorScheme, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header: nút back + tiêu đề + nút "Đánh dấu đã đọc".
  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        AppConstants.paddingSM + 4,
      ),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkBackground : AppColors.lightBackground)
            .withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Nút back
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                size: AppConstants.iconSizeMD,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
          // Tiêu đề
          Text(
            'Thông báo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Nút đánh dấu tất cả đã đọc
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              if (widget.controller.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: widget.controller.markAllAsRead,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSM,
                    vertical: AppConstants.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSM),
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    'Đánh dấu đã đọc',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Danh sách thông báo phân nhóm theo ngày.
  Widget _buildNotificationList(ColorScheme colorScheme, bool isDark) {
    final today = widget.controller.todayNotifications;
    final yesterday = widget.controller.yesterdayNotifications;
    final older = widget.controller.olderNotifications;

    return RefreshIndicator(
      onRefresh: () => widget.controller.loadNotifications(refresh: true),
      color: colorScheme.primary,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
        ),
        children: [
          if (today.isNotEmpty) ...[
            _buildSectionHeader('Hôm nay', isDark),
            ...today.map((n) => _buildCard(n)),
          ],
          if (yesterday.isNotEmpty) ...[
            _buildSectionHeader('Hôm qua', isDark),
            ...yesterday.map((n) => _buildCard(n)),
          ],
          if (older.isNotEmpty) ...[
            _buildSectionHeader('Cũ hơn', isDark),
            ...older.map((n) => _buildCard(n)),
          ],
          // Loading more indicator
          if (widget.controller.isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppConstants.paddingMD),
        ],
      ),
    );
  }

  /// Header nhóm ngày (VD: "HÔM NAY").
  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppConstants.paddingSM + 4,
        bottom: AppConstants.paddingSM + 4,
        left: 4,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  /// Build card cho mỗi thông báo.
  Widget _buildCard(NotificationModel notification) {
    return NotificationCardWidget(
      notification: notification,
      onTap: () {
        if (!notification.isRead) {
          widget.controller.markAsRead(notification.id);
        }
        NotificationDetailBottomSheet.show(
          context,
          notification,
          onViewTicket: widget.onViewTicket,
        );
      },
    );
  }

  /// Loading indicator khi đang tải lần đầu.
  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
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
            'Đang tải thông báo...',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Trạng thái không có thông báo.
  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSM),
          Text(
            'Thông báo về chuyến xe, điểm danh sẽ\nhiển thị tại đây',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
          ),
        ],
      ),
    );
  }

  /// Trạng thái lỗi.
  Widget _buildErrorState(
    ColorScheme colorScheme,
    bool isDark,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppConstants.paddingMD),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMD),
            ElevatedButton(
              onPressed: () =>
                  widget.controller.loadNotifications(refresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
