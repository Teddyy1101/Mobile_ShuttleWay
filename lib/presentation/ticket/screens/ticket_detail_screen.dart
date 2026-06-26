import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/ticket_model.dart';

/// Màn hình chi tiết vé xe dạng thẻ (card) với mã QR tự động refresh.
class TicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  late Timer _qrRefreshTimer;
  late String _qrData;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final GlobalKey _ticketKey = GlobalKey();
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _generateQrData();

    // Tự động refresh QR mỗi 30 giây
    _qrRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _generateQrData(),
    );

    // Hiệu ứng pulse nhẹ cho QR code
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _qrRefreshTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Tạo chuỗi JSON mới cho QR code với timestamp hiện tại.
  void _generateQrData() {
    final data = jsonEncode({
      'ticketId': widget.ticket.id,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    if (mounted) {
      setState(() => _qrData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _buildAppBar(theme, isDark, backgroundColor),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: AppConstants.paddingXXL,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.paddingSM),
                  RepaintBoundary(
                    key: _ticketKey,
                    child: _buildTicketCard(theme, isDark),
                  ),
                  const SizedBox(height: AppConstants.paddingLG),
                  _buildActionButtons(theme, isDark),
                ],
              ),
            ),
          ),
        ],
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
                'Chi tiết vé xe',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppConstants.avatarSizeMD),
          ],
        ),
      ),
    );
  }

  // ─── Ticket Card ──────────────────────────────────────────

  Widget _buildTicketCard(ThemeData theme, bool isDark) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            // Accent bar phía trên
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusXL),
                ),
              ),
            ),
            // Header: Bus Ticket + Badge trạng thái
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingLG,
                AppConstants.paddingMD + 4,
                AppConstants.paddingLG,
                0,
              ),
              child: _buildCardHeader(theme, isDark),
            ),
            // Student info + Avatar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLG,
                vertical: AppConstants.paddingMD,
              ),
              child: _buildStudentSection(theme, isDark),
            ),
            // QR Code
            _buildQrSection(theme, isDark),
            // Dashed divider với notch tròn
            _buildNotchDivider(isDark),
            // Thông tin vé chi tiết
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingLG,
                AppConstants.paddingSM,
                AppConstants.paddingLG,
                AppConstants.paddingLG + 4,
              ),
              child: _buildTicketDetails(theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(ThemeData theme, bool isDark) {
    final isActive = widget.ticket.status == 'ACTIVE';
    final statusLabel = isActive ? 'Hiệu lực' : widget.ticket.status;
    final statusColor = isActive ? AppColors.success : AppColors.warning;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.directions_bus,
              size: AppConstants.iconSizeSM,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppConstants.paddingSM),
            Text(
              'BUS TICKET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingSM + 2,
            vertical: AppConstants.paddingXS,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSection(ThemeData theme, bool isDark) {
    final student = widget.ticket.student;
    final studentName = student?.fullName ?? 'N/A';

    return Column(
      children: [
        // Avatar
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  width: 4,
                ),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage: student?.avatarUrl != null
                    ? NetworkImage(student!.avatarUrl!)
                    : null,
                child: student?.avatarUrl == null
                    ? Text(
                        studentName.isNotEmpty
                            ? studentName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 24,
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
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.school,
                  size: 12,
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingSM + 4),
        // Tên & mã vé
        Text(
          studentName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingXS),
        Text(
          'Mã vé: #${widget.ticket.id.substring(0, 6).toUpperCase()}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
          ),
        ),
      ],
    );
  }

  Widget _buildQrSection(ThemeData theme, bool isDark) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingSM + 4),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppConstants.radiusLG),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder.withValues(alpha: 0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 160,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1A1D2E),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Color(0xFF1A1D2E),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingSM + 4),
        Text(
          'Đưa mã này vào thiết bị quét trên xe buýt để điểm danh',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.paddingXS),
        // Countdown indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.autorenew,
              size: 14,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: AppConstants.paddingXS),
            Text(
              'QR tự động cập nhật mỗi 30 giây',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotchDivider(bool isDark) {
    return SizedBox(
      height: AppConstants.paddingXL,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dashed line ở giữa
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLG,
                ),
                child: CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _DashedHorizontalPainter(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
            ),
          ),
          // Notch trái
          Positioned(
            left: -AppConstants.paddingSM,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: AppConstants.paddingMD,
                height: AppConstants.paddingMD,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Notch phải
          Positioned(
            right: -AppConstants.paddingSM,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: AppConstants.paddingMD,
                height: AppConstants.paddingMD,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetails(ThemeData theme, bool isDark) {
    final routeName = widget.ticket.route?.name ?? 'N/A';
    final validUntilStr =
        DateFormat('dd/MM/yyyy').format(widget.ticket.validUntil);
    final ticketTypeLabel =
        widget.ticket.ticketType == 'MONTHLY' ? 'Vé tháng' : 'Vé lượt';

    final labelColor =
        isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final valueColor = theme.colorScheme.onSurface;

    return Column(
      children: [
        // Row 1: Tuyến đường + Loại vé
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                label: 'TUYẾN ĐƯỜNG',
                value: routeName,
                labelColor: labelColor,
                valueColor: valueColor,
              ),
            ),
            Expanded(
              child: _buildDetailItem(
                label: 'LOẠI VÉ',
                value: ticketTypeLabel,
                labelColor: labelColor,
                valueColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingLG),
        // Row 2: Hạn sử dụng + Giá vé
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                label: 'HẠN SỬ DỤNG',
                value: validUntilStr,
                labelColor: labelColor,
                valueColor: valueColor,
              ),
            ),
            Expanded(
              child: _buildDetailItem(
                label: 'GIÁ VÉ',
                value: '${_formatCurrency(widget.ticket.priceAtBuy)}đ',
                labelColor: labelColor,
                valueColor: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: labelColor,
          ),
        ),
        const SizedBox(height: AppConstants.paddingXS),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── Action Buttons ──────────────────────────────────────

  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          // Nút Chia sẻ
          Expanded(
            child: _buildOutlineButton(
              icon: Icons.share,
              label: 'Chia sẻ',
              theme: theme,
              isDark: isDark,
              onTap: () {
                // TODO: implement share
              },
            ),
          ),
          const SizedBox(width: AppConstants.paddingMD),
          // Nút Tải về
          Expanded(
            child: _buildPrimaryButton(
              icon: Icons.download,
              label: 'Tải vé về',
              theme: theme,
              isLoading: _isDownloading,
              onTap: _isDownloading ? () {} : _handleDownloadTicket,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineButton({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingMD,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppConstants.iconSizeSM,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: AppConstants.paddingSM),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      elevation: 4,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingMD,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: AppConstants.iconSizeSM,
                  height: AppConstants.iconSizeSM,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkTextPrimary),
                  ),
                )
              else
                Icon(
                  icon,
                  size: AppConstants.iconSizeSM,
                  color: AppColors.darkTextPrimary,
                ),
              const SizedBox(width: AppConstants.paddingSM),
              Text(
                isLoading ? 'Đang tải...' : label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownloadTicket() async {
    setState(() => _isDownloading = true);

    try {
      // Yêu cầu quyền lưu ảnh
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final requestResult = await Gal.requestAccess(toAlbum: true);
        if (!requestResult) {
          if (mounted) {
            AppToast.showError(
              context,
              'Cần cấp quyền truy cập thư viện ảnh',
            );
          }
          return;
        }
      }

      // Đợi rendering xong trước khi capture
      await Future.delayed(const Duration(milliseconds: 200));

      // Capture thẻ vé qua RepaintBoundary
      final boundary = _ticketKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          AppToast.showError(context, 'Không thể tải vé');
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        if (mounted) {
          AppToast.showError(context, 'Không thể xuất ảnh vé');
        }
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Lưu vào Gallery qua Gal
      await Gal.putImageBytes(pngBytes, album: 'SafeWheels');

      if (mounted) {
        AppToast.showSuccess(context, 'Đã lưu vé vào thư viện ảnh');
      }
    } on GalException catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Không thể lưu ảnh: ${e.type.name}');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Lỗi khi tải vé: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount.abs());
  }
}

/// Custom painter cho đường nét đứt ngang (dashed horizontal line).
class _DashedHorizontalPainter extends CustomPainter {
  final Color color;

  _DashedHorizontalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const gapWidth = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
