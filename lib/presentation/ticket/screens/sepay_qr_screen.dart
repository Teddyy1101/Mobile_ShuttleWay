import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/ticket_model.dart';
import '../controllers/payment_controller.dart';
import 'ticket_detail_screen.dart';

/// Thông tin ngân hàng nhận thanh toán SePay.
class _BankConfig {
  static const String bankId = 'MB';
  static const String accountNo = '0968312282';
  static const String accountName = 'NGUYEN HUY THU';
  static const String bankName = 'MB Bank';
  static const String template = 'compact2';
}

/// Màn hình thanh toán QR chuyển khoản SePay.
///
/// Hiển thị mã VietQR để chuyển khoản, đếm ngược 10 phút,
/// tự động polling kiểm tra trạng thái giao dịch.
/// Hỗ trợ lưu ảnh QR về máy.
class SePayQrScreen extends StatefulWidget {
  final TicketModel ticket;
  final PaymentController paymentController;

  const SePayQrScreen({
    super.key,
    required this.ticket,
    required this.paymentController,
  });

  @override
  State<SePayQrScreen> createState() => _SePayQrScreenState();
}

class _SePayQrScreenState extends State<SePayQrScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _captureKey = GlobalKey();
  late Timer _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _remainingSeconds = PaymentController.pollingMaxSeconds;
  bool _isSaving = false;

  /// Nội dung chuyển khoản: BUS <transactionId>.
  String get _transferContent =>
      'BUS ${widget.paymentController.transaction!.id}';

  /// Số tiền thanh toán.
  double get _amount =>
      widget.paymentController.transaction!.finalAmount;

  /// URL ảnh VietQR được tạo từ API img.vietqr.io.
  String get _vietQrUrl {
    final amount = _amount.toInt();
    final info = Uri.encodeComponent(_transferContent);
    final accName = Uri.encodeComponent(_BankConfig.accountName);
    return 'https://img.vietqr.io/image/'
        '${_BankConfig.bankId}-${_BankConfig.accountNo}-${_BankConfig.template}.png'
        '?amount=$amount&addInfo=$info&accountName=$accName';
  }

  @override
  void initState() {
    super.initState();

    // Pulse animation cho indicator chờ
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Countdown timer mỗi giây
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _countdownTimer.cancel();
          }
        });
      },
    );

    // Bắt đầu polling kiểm tra trạng thái
    widget.paymentController.startPolling(
      widget.paymentController.transaction!.id,
      onResult: _handlePollingResult,
    );
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _pulseController.dispose();
    widget.paymentController.stopPolling();
    super.dispose();
  }

  /// Xử lý kết quả polling.
  void _handlePollingResult() {
    if (!mounted) return;
    final status = widget.paymentController.pollingStatus;

    if (status == 'SUCCESS') {
      _showSuccessDialog();
    } else if (status == 'TIMEOUT') {
      AppToast.showError(context, 'Hết thời gian chờ thanh toán');
      Navigator.pop(context);
    } else if (status == 'FAILED') {
      AppToast.showError(context, 'Giao dịch thất bại');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildAppBar(theme, isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: AppConstants.paddingXXL,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.paddingMD),
                  _buildCountdown(theme, isDark),
                  const SizedBox(height: AppConstants.paddingLG),
                  _buildQrCard(theme, isDark),
                  const SizedBox(height: AppConstants.paddingLG),
                  _buildTransferInfo(theme, isDark),
                  const SizedBox(height: AppConstants.paddingLG),
                  _buildSaveButton(theme, isDark),
                  const SizedBox(height: AppConstants.paddingMD),
                  _buildPollingIndicator(theme, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────

  Widget _buildAppBar(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
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
              onPressed: () => _confirmExit(),
              icon: Icon(
                Icons.close,
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
                'Chuyển khoản QR',
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

  // Countdown Timer

  Widget _buildCountdown(ThemeData theme, bool isDark) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isLow = _remainingSeconds < 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: AppConstants.paddingSM + 4,
        ),
        decoration: BoxDecoration(
          color: (isLow ? AppColors.error : theme.colorScheme.primary)
              .withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: (isLow ? AppColors.error : theme.colorScheme.primary)
                .withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 20,
              color: isLow ? AppColors.error : theme.colorScheme.primary,
            ),
            const SizedBox(width: AppConstants.paddingSM),
            Text(
              'Thời gian còn lại: ',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isLow ? AppColors.error : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // QR Card (VietQR)

  Widget _buildQrCard(ThemeData theme, bool isDark) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;

    return RepaintBoundary(
      key: _captureKey,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
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
              // Thanh accent trên cùng
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.radiusXL),
                  ),
                ),
              ),
              // Logo + tiêu đề
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingLG,
                  AppConstants.paddingMD,
                  AppConstants.paddingLG,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSM),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'MB',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingSM),
                    Text(
                      _BankConfig.bankName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingMD),
              // VietQR Image
              _buildQrImage(theme, isDark),
              const SizedBox(height: AppConstants.paddingMD),
              // Số tiền
              _buildAmountBadge(theme, isDark),
              const SizedBox(height: AppConstants.paddingLG),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget hiển thị ảnh VietQR từ API img.vietqr.io.
  Widget _buildQrImage(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(
          color: AppColors.lightBorder.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        child: Image.network(
          _vietQrUrl,
          width: double.infinity,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              height: 280,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 40,
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppConstants.paddingSM),
                  Text(
                    'Không thể tải mã QR',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Badge hiển thị số tiền thanh toán.
  Widget _buildAmountBadge(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingSM + 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Số tiền',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            '${_formatCurrency(_amount)}đ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Transfer Info

  Widget _buildTransferInfo(ThemeData theme, bool isDark) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              'Ngân hàng',
              _BankConfig.bankName,
              theme,
              isDark,
            ),
            _buildInfoDivider(isDark),
            _buildInfoRow(
              'Số tài khoản',
              _BankConfig.accountNo,
              theme,
              isDark,
            ),
            _buildInfoDivider(isDark),
            _buildInfoRow(
              'Chủ tài khoản',
              _BankConfig.accountName,
              theme,
              isDark,
            ),
            _buildInfoDivider(isDark),
            _buildInfoRow(
              'Nội dung CK',
              _transferContent,
              theme,
              isDark,
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextHint
                  : AppColors.lightTextHint,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isHighlight
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark
          ? AppColors.darkBorder.withValues(alpha: 0.3)
          : AppColors.lightBorder.withValues(alpha: 0.5),
    );
  }

  // Save Button

  Widget _buildSaveButton(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isSaving ? null : _saveQrImage,
          icon: _isSaving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.download_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
          label: Text(
            _isSaving ? 'Đang lưu...' : 'Tải ảnh QR về máy',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingMD,
            ),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
        ),
      ),
    );
  }

  // Polling Indicator

  Widget _buildPollingIndicator(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: child,
        );
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingSM + 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppConstants.paddingSM),
              Flexible(
                child: Text(
                  'Đang chờ xác nhận chuyển khoản...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Actions

  /// Lưu ảnh QR thanh toán (RepaintBoundary capture) vào Gallery.
  Future<void> _saveQrImage() async {
    setState(() => _isSaving = true);

    try {
      // Xin quyền lưu ảnh
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          if (mounted) {
            AppToast.showError(
              context,
              'Cần cấp quyền truy cập thư viện ảnh',
            );
          }
          return;
        }
      }

      // Capture khu vực QR qua RepaintBoundary
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          AppToast.showError(context, 'Không thể capture ảnh QR');
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        if (mounted) {
          AppToast.showError(context, 'Không thể xuất ảnh');
        }
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Lưu vào Gallery qua Gal
      await Gal.putImageBytes(pngBytes, album: 'SafeWheels');

      if (mounted) {
        AppToast.showSuccess(context, 'Đã lưu ảnh QR vào thư viện ảnh');
      }
    } on GalException catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Không thể lưu ảnh: ${e.type.name}');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Lỗi khi lưu ảnh: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Hỏi xác nhận khi user muốn thoát.
  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
          title: Text(
            'Hủy thanh toán?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Giao dịch sẽ bị hủy nếu bạn thoát trước khi '
            'hoàn tất chuyển khoản.',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Ở lại',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Đóng dialog
                Navigator.pop(context); // Thoát screen
              },
              child: const Text(
                'Thoát',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Hiển thị dialog thành công + chuyển sang TicketDetailScreen.
  void _showSuccessDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLG + 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSuccessIcon(),
                const SizedBox(height: AppConstants.paddingLG),
                Text(
                  'Thanh toán thành công!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingSM),
                Text(
                  'Vé xe đã được kích hoạt.\n'
                  'Bạn có thể xem chi tiết vé ngay bây giờ.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingLG + 4),
                _buildViewTicketButton(ctx, theme),
                const SizedBox(height: AppConstants.paddingSM + 4),
                _buildBackButton(ctx, theme, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Icon thành công với animation scale.
  Widget _buildSuccessIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 32,
              color: AppColors.success,
            ),
          ),
        ),
      ),
    );
  }

  /// Nút "Xem vé" — chuyển sang TicketDetailScreen.
  Widget _buildViewTicketButton(BuildContext ctx, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(ctx); // Đóng dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(
                ticket: widget.ticket,
              ),
            ),
          );
        },
        icon: const Icon(Icons.confirmation_number_outlined, size: 20),
        label: const Text(
          'Xem vé',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// Nút "Quay lại" — pop về BookTicketScreen.
  Widget _buildBackButton(BuildContext ctx, ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(ctx); // Đóng dialog
          Navigator.pop(context); // Quay về PaymentScreen
          Navigator.pop(context); // Quay về BookTicketScreen
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
        ),
        child: const Text(
          'Quay lại',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Helpers

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount.abs());
  }
}
