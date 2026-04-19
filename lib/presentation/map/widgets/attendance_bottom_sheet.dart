import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../screens/qr_scanner_screen.dart';

class AttendanceBottomSheet extends StatefulWidget {
  final String tripId;
  final String stationId;
  final String stationName;
  final List<Map<String, dynamic>> studentsToPickUp;
  final List<Map<String, dynamic>> studentsToDropOff;
  final DriverHomeController controller;

  const AttendanceBottomSheet({
    super.key,
    required this.tripId,
    required this.stationId,
    required this.stationName,
    required this.studentsToPickUp,
    required this.studentsToDropOff,
    required this.controller,
  });

  @override
  State<AttendanceBottomSheet> createState() => _AttendanceBottomSheetState();
}

class _AttendanceBottomSheetState extends State<AttendanceBottomSheet> {
  /// Lưu trạng thái điểm danh local: studentId → status
  final Map<String, String> _localStatus = {};

  /// Đang xử lý điểm danh cho studentId nào.
  final Set<String> _processingIds = {};

  /// Các studentId đã được quét QR → khoá nút chọn thủ công.
  final Set<String> _qrVerifiedIds = {};

  /// Mutable student lists (để reload từ API).
  late List<Map<String, dynamic>> _studentsToPickUp;
  late List<Map<String, dynamic>> _studentsToDropOff;

  @override
  void initState() {
    super.initState();
    _studentsToPickUp = List.from(widget.studentsToPickUp);
    _studentsToDropOff = List.from(widget.studentsToDropOff);
    _initLocalStatus();
  }

  /// Khởi tạo hoặc cập nhật _localStatus từ student lists.
  void _initLocalStatus() {
    for (final s in _studentsToPickUp) {
      final studentId = s['student']?['id'] as String? ?? '';
      _localStatus[studentId] = s['status'] as String? ?? 'PENDING';
    }
    for (final s in _studentsToDropOff) {
      final studentId = s['student']?['id'] as String? ?? '';
      _localStatus[studentId] = s['status'] as String? ?? 'BOARDED';
    }
  }

  /// Reload dữ liệu học sinh từ API và cập nhật local state.
  Future<void> _reloadStudents() async {
    final data = await widget.controller.getStudentsAtStation(
      widget.tripId,
      widget.stationId,
    );
    if (!mounted) return;

    final pickUp = (data['studentsToPickUp'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final dropOff = (data['studentsToDropOff'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    setState(() {
      _studentsToPickUp = pickUp;
      _studentsToDropOff = dropOff;
      _localStatus.clear();
      _initLocalStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
          _buildHeader(colorScheme, isDark),

          // ─── Danh sách học sinh ───
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_studentsToPickUp.isNotEmpty) ...[
                    _buildSectionTitle(
                      'Học sinh lên xe',
                      Icons.login_rounded,
                      AppColors.success,
                      colorScheme,
                    ),
                    const SizedBox(height: AppConstants.paddingSM),
                    ..._studentsToPickUp.map(
                      (s) => _buildStudentItem(s, 'BOARDED', isDark, colorScheme),
                    ),
                    const SizedBox(height: AppConstants.paddingMD),
                  ],
                  if (_studentsToDropOff.isNotEmpty) ...[
                    _buildSectionTitle(
                      'Học sinh xuống xe',
                      Icons.logout_rounded,
                      AppColors.warning,
                      colorScheme,
                    ),
                    const SizedBox(height: AppConstants.paddingSM),
                    ..._studentsToDropOff.map(
                      (s) => _buildStudentItem(s, 'ALIGHTED', isDark, colorScheme),
                    ),
                  ],
                  const SizedBox(height: AppConstants.paddingMD),
                ],
              ),
            ),
          ),

          // ─── Bottom actions ───
          _buildBottomActions(colorScheme, isDark),
        ],
      ),
    );
  }

  /// Header: Tên trạm + badge
  Widget _buildHeader(ColorScheme colorScheme, bool isDark) {
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
              Icons.fact_check_rounded,
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
                  'ĐIỂM DANH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.stationName,
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
          _buildStudentCount(colorScheme),
        ],
      ),
    );
  }

  Widget _buildStudentCount(ColorScheme colorScheme) {
    final total =
        _studentsToPickUp.length + _studentsToDropOff.length;
    return Container(
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
    );
  }

  /// Tiêu đề section (Lên xe / Xuống xe)
  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color accentColor,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Card học sinh với 2 nút hành động.
  Widget _buildStudentItem(
    Map<String, dynamic> attendanceData,
    String targetStatus,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final student = attendanceData['student'] as Map<String, dynamic>? ?? {};
    final studentId = student['id'] as String? ?? '';
    final studentName = student['fullName'] as String? ?? 'N/A';
    final avatarUrl = student['avatarUrl'] as String?;
    final currentStatus = _localStatus[studentId] ?? 'PENDING';
    final isProcessing = _processingIds.contains(studentId);
    final isQrVerified = _qrVerifiedIds.contains(studentId);

    final isMarked =
        currentStatus == 'BOARDED' || currentStatus == 'ALIGHTED';
    final isAbsent = currentStatus == 'ABSENT';

    // Khoá thao tác thủ công nếu đã quét QR
    final isLocked = isQrVerified && isMarked;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSM),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: isMarked
              ? AppColors.success.withValues(alpha: 0.4)
              : isAbsent
                  ? AppColors.error.withValues(alpha: 0.4)
                  : isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    studentName.isNotEmpty
                        ? studentName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Tên + trạng thái — bấm vào hiện chi tiết HS
          Expanded(
            child: GestureDetector(
              onTap: () => _showStudentDetail(student, currentStatus, colorScheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _getStatusLabel(currentStatus),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(currentStatus),
                        ),
                      ),
                      if (isQrVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.qr_code_rounded,
                          size: 12,
                          color: AppColors.success,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Nút hành động
          if (isProcessing)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isLocked)
            // Đã quét QR → hiển thị badge khoá
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'QR ✓',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Nút Có mặt
            _buildActionChip(
              icon: Icons.check_rounded,
              label: 'Có mặt',
              color: AppColors.success,
              isActive: isMarked,
              onTap: isMarked
                  ? null
                  : () => _handleMark(studentId, targetStatus),
            ),
            const SizedBox(width: 6),
            // Nút Vắng
            _buildActionChip(
              icon: Icons.close_rounded,
              label: 'Vắng',
              color: AppColors.error,
              isActive: isAbsent,
              onTap: isAbsent
                  ? null
                  : () => _handleMark(studentId, 'ABSENT'),
            ),
          ],
        ],
      ),
    );
  }

  /// Chip hành động nhỏ (Có mặt / Vắng).
  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom: Nút QR + Đóng
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
          // Nút Đóng & Tiếp tục
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text('Đóng & Tiếp tục'),
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

  // ─── Handlers ───

  /// Điểm danh thủ công.
  Future<void> _handleMark(String studentId, String status) async {
    setState(() => _processingIds.add(studentId));

    final success = await widget.controller.markAttendance(
      widget.tripId,
      studentId,
      status,
    );

    if (mounted) {
      setState(() {
        _processingIds.remove(studentId);
        if (success) {
          _localStatus[studentId] = status;
        }
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.errorMessage ?? 'Điểm danh thất bại',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Mở QR scanner.
  Future<void> _handleOpenQrScanner() async {
    final ticketId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (ticketId == null || !mounted) return;

    // Hiển thị loading
    _showLoadingDialog();

    final result = await widget.controller.verifyTicket(
      widget.tripId,
      ticketId,
    );

    if (!mounted) return;
    Navigator.pop(context); // Đóng loading dialog

    if (result != null) {
      // Tìm studentId từ result để cập nhật local
      final resultData = result['result'] as Map<String, dynamic>?;
      final alreadyMarked = resultData?['alreadyMarked'] as bool? ?? false;
      final studentData =
          resultData?['student'] as Map<String, dynamic>?;
      final studentId = studentData?['id'] as String?;
      final studentName = studentData?['fullName'] as String? ?? 'Học sinh';

      if (alreadyMarked) {
        // Học sinh đã được điểm danh trước đó
        if (studentId != null) {
          setState(() {
            _localStatus[studentId] = 'BOARDED';
            _qrVerifiedIds.add(studentId);
          });
        }
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
        // Điểm danh thành công
        if (studentId != null) {
          setState(() {
            _localStatus[studentId] = 'BOARDED';
            _qrVerifiedIds.add(studentId);
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Điểm danh thành công: $studentName'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Reload dữ liệu mới từ API để đồng bộ chính xác
      await _reloadStudents();
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

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  // ─── Helpers ───

  /// Hiển thị dialog chi tiết thông tin học sinh.
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(currentStatus).withValues(alpha: 0.12),
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
                _buildDetailRow(Icons.phone_rounded, 'SĐT', phone, colorScheme),
              if (email != null && email.isNotEmpty)
                _buildDetailRow(Icons.email_rounded, 'Email', email, colorScheme),
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
          Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
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
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}

/// Hiển thị bottom sheet điểm danh.
///
/// Gọi API lấy danh sách học sinh tại trạm, nếu có thì show sheet,
/// nếu không thì show SnackBar thông báo.
Future<void> showAttendanceSheet({
  required BuildContext context,
  required String tripId,
  required String stationId,
  required String stationName,
  required DriverHomeController controller,
}) async {
  final data = await controller.getStudentsAtStation(tripId, stationId);

  if (!context.mounted) return;

  final pickUp = (data['studentsToPickUp'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [];
  final dropOff = (data['studentsToDropOff'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [];

  if (pickUp.isEmpty && dropOff.isEmpty) {
    // Không có học sinh → popup thông báo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Trạm "$stationName" không có học sinh lên/xuống xe',
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  // Có học sinh → hiển thị bottom sheet
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AttendanceBottomSheet(
      tripId: tripId,
      stationId: stationId,
      stationName: stationName,
      studentsToPickUp: pickUp,
      studentsToDropOff: dropOff,
      controller: controller,
    ),
  );
}
