import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Kết quả trả về khi WebView chặn được redirect VNPay/MoMo.
class PaymentWebViewResult {
  /// `true` nếu thanh toán thành công.
  ///
  /// - VNPay: `vnp_ResponseCode == '00'`
  /// - MoMo: `resultCode == '0'`
  final bool isSuccess;

  /// Mã giao dịch tham chiếu.
  ///
  /// - VNPay: `vnp_TxnRef`
  /// - MoMo: `orderId`
  final String? transactionRef;

  /// Mã response từ cổng thanh toán (dùng để hiển thị lỗi chi tiết).
  ///
  /// - VNPay: `vnp_ResponseCode`
  /// - MoMo: `resultCode`
  final String? responseCode;

  const PaymentWebViewResult({
    required this.isSuccess,
    this.transactionRef,
    this.responseCode,
  });
}

/// Màn hình WebView tải URL thanh toán VNPay/MoMo.
///
/// Lắng nghe mọi URL redirect. Khi phát hiện URL chứa `vnpay/return`
/// hoặc `momo/return`, chặn load và trả về [PaymentWebViewResult]
/// qua `Navigator.pop`.
class PaymentWebViewScreen extends StatefulWidget {
  /// URL thanh toán lấy từ backend (VNPay hoặc MoMo).
  final String paymentUrl;

  /// Tiêu đề hiển thị trên AppBar.
  final String title;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    this.title = 'Thanh toán',
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  /// Khởi tạo WebView controller với NavigationDelegate để chặn redirect.
  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;

            // Chặn các URL scheme không phải HTTP/HTTPS
            // (market://, intent://, vd: MoMo cố mở CH Play)
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }

            // Chặn redirect VNPay return
            if (url.contains('vnpay/return')) {
              _handleVnPayReturn(url);
              return NavigationDecision.prevent;
            }

            // Chặn redirect MoMo return
            if (url.contains('momo/return')) {
              _handleMoMoReturn(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  /// Parse query params từ URL redirect VNPay và trả kết quả về cho caller.
  void _handleVnPayReturn(String url) {
    final uri = Uri.parse(url);
    final responseCode = uri.queryParameters['vnp_ResponseCode'];
    final txnRef = uri.queryParameters['vnp_TxnRef'];

    final result = PaymentWebViewResult(
      isSuccess: responseCode == '00',
      transactionRef: txnRef,
      responseCode: responseCode,
    );

    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  /// Parse query params từ URL redirect MoMo và trả kết quả về cho caller.
  ///
  /// MoMo redirect URL chứa các param:
  /// - `resultCode`: `0` = thành công, khác `0` = thất bại
  /// - `orderId`: mã đơn hàng (format: transactionId-timestamp)
  void _handleMoMoReturn(String url) {
    final uri = Uri.parse(url);
    final resultCode = uri.queryParameters['resultCode'];
    final orderId = uri.queryParameters['orderId'];

    final result = PaymentWebViewResult(
      isSuccess: resultCode == '0',
      transactionRef: orderId,
      responseCode: resultCode,
    );

    if (mounted) {
      Navigator.pop(context, result);
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
          if (_isLoading)
            LinearProgressIndicator(
              color: theme.colorScheme.primary,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }

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
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Lock icon để thể hiện bảo mật
            Padding(
              padding: const EdgeInsets.only(right: AppConstants.paddingSM),
              child: Icon(
                Icons.lock_outline,
                size: AppConstants.iconSizeSM,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
