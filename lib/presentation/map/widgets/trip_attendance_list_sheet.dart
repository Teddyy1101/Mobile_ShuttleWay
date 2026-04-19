import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../screens/qr_scanner_screen.dart';

class TripAttendanceListSheet extends StatefulWidget {
  final String tripId;
  final String tripName;
  final DriverHomeController controller;

  const TripAttendanceListSheet({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.controller,
  });

  @override
  State<TripAttendanceListSheet> createState() =>
      _TripAttendanceListSheetState();
}

class _TripAttendanceListSheetState extends State<TripAttendanceListSheet> {
  List<Map<String, dynamic>> _attendances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() => _isLoading = true);
    final data = await widget.controller.getTripAttendances(widget.tripId);
    if (mounted) {
      setState(() {
        _attendances = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final boarded = _attendances
        .where(
            (a) => a['status'] == 'BOARDED' || a['status'] == 'ALIGHTED')
        .length;
    final absent =
        _attendances.where((a) => a['status'] == 'ABSENT').length;
    final pending =
        _attendances.where((a) => a['status'] == 'PENDING').length;
    final total = _attendances.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Handle bar ───
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppConstants.paddingSM + 4),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ─── Header ───
          _buildHeader(colorScheme, isDark, total),

          // ─── Thống kê nhanh ───
          if (!_isLoading)
            _buildQuickStats(colorScheme, isDark, boarded, absent, pending),

          // ─── Danh sách ───
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _attendances.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : RefreshIndicator(
                        onRefresh: _loadAttendances,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMD,
                          ),
                          itemCount: _attendances.length,
                          itemBuilder: (context, index) => _buildStudentTile(
                            _attendances[index],
                            isDark,
                            colorScheme,
                          ),
                        ),
                      ),
          ),

          // ─── Bottom: Quét QR + Đóng ───
          _buildBottomActions(colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, bool isDark, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        AppConstants.paddingSM,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.people_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DANH SÁCH ĐIỂM DANH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.tripName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$total HS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    ColorScheme colorScheme,
    bool isDark,
    int boarded,
    int absent,
    int pending,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        margin: const EdgeInsets.only(bottom: AppConstants.paddingSM),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard
              : colorScheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatChip(
              'Có mặt',
              boarded,
              AppColors.success,
            ),
            Container(
              width: 1,
              height: 28,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            _buildStatChip(
              'Vắng',
              absent,
              AppColors.error,
            ),
            Container(
              width: 1,
              height: 28,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            _buildStatChip(
              'Chờ',
              pending,
              AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentTile(
    Map<String, dynamic> attendance,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final student = attendance['student'] as Map<String, dynamic>? ?? {};
    final name = student['fullName'] as String? ?? 'N/A';
    final avatarUrl = student['avatarUrl'] as String?;
    final status = attendance['status'] as String? ?? 'PENDING';

    final isPresent = status == 'BOARDED' || status == 'ALIGHTED';
    final isAbsent = status == 'ABSENT';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: isPresent
              ? AppColors.success.withValues(alpha: 0.3)
              : isAbsent
                  ? AppColors.error.withValues(alpha: 0.3)
                  : isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Tên
          Expanded(
            child: GestureDetector(
              onTap: () => _showStudentDetail(student, status, colorScheme),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: colorScheme.primary.withValues(alpha: 0.4),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Badge trạng thái
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 14,
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có học sinh nào',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingSM,
        AppConstants.paddingMD,
        MediaQuery.of(context).padding.bottom + AppConstants.paddingMD,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.8)
            : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Nút Quét QR
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _handleOpenQrScanner,
              icon: Icon(
                Icons.qr_code_scanner_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              label: Text(
                'Quét QR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
          // Nút Đóng
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text('Đóng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

  /// Mở QR scanner và điểm danh.
  Future<void> _handleOpenQrScanner() async {
    final ticketId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (ticketId == null || !mounted) return;

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final result = await widget.controller.verifyTicket(
      widget.tripId,
      ticketId,
    );

    if (!mounted) return;
    Navigator.pop(context); // Đóng loading

    if (result != null) {
      final resultData = result['result'] as Map<String, dynamic>?;
      final alreadyMarked = resultData?['alreadyMarked'] as bool? ?? false;
      final studentName =
          resultData?['student']?['fullName'] as String? ?? 'Học sinh';

      if (alreadyMarked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Vé đã được quét trước đó ($studentName)'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Điểm danh thành công: $studentName'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Reload danh sách
      _loadAttendances();
    } else {
      final errMsg =
          widget.controller.errorMessage ?? 'Xác minh vé thất bại';
      final isRouteMismatch = errMsg.contains('không thuộc tuyến đường');
      final isExpiredTicket = errMsg.contains('không còn hiệu lực');
      final isWarning = isRouteMismatch || isExpiredTicket;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isRouteMismatch
                    ? Icons.wrong_location_rounded
                    : isExpiredTicket
                        ? Icons.block_rounded
                        : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(errMsg)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isWarning ? AppColors.warning : AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Hiển thị dialog chi tiết học sinh.
  void _showStudentDetail(
    Map<String, dynamic> student,
    String currentStatus,
    ColorScheme colorScheme,
  ) {
    final name = student['fullName'] as String? ?? 'N/A';
    final phone = student['phone'] as String?;
    final email = student['email'] as String?;
    final avatarUrl = student['avatarUrl'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingLG),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(currentStatus).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(currentStatus),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(currentStatus),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (phone != null && phone.isNotEmpty)
                _buildDetailRow(
                    Icons.phone_rounded, 'SĐT', phone, colorScheme),
              if (email != null && email.isNotEmpty)
                _buildDetailRow(
                    Icons.email_rounded, 'Email', email, colorScheme),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───

  String _getStatusLabel(String status) {
    return switch (status) {
      'BOARDED' => 'Đã lên xe',
      'ALIGHTED' => 'Đã xuống xe',
      'ABSENT' => 'Vắng mặt',
      _ => 'Chờ điểm danh',
    };
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'BOARDED' || 'ALIGHTED' => AppColors.success,
      'ABSENT' => AppColors.error,
      _ => AppColors.warning,
    };
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'BOARDED' || 'ALIGHTED' => Icons.check_circle_rounded,
      'ABSENT' => Icons.cancel_rounded,
      _ => Icons.schedule_rounded,
    };
  }
}

/// Hàm tiện ích mở danh sách điểm danh toàn chuyến.
Future<void> showTripAttendanceList({
  required BuildContext context,
  required String tripId,
  required String tripName,
  required DriverHomeController controller,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TripAttendanceListSheet(
      tripId: tripId,
      tripName: tripName,
      controller: controller,
    ),
  );
}
