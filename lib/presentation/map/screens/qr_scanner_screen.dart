import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _hasScanned = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─── Camera ───
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // ─── Overlay scan area ───
          _buildScanOverlay(colorScheme),

          // ─── Top bar ───
          _buildTopBar(context, isDark, colorScheme),

          // ─── Bottom info / error ───
          _buildBottomInfo(isDark, colorScheme),
        ],
      ),
    );
  }

  /// Overlay tạo vùng scan hình vuông ở giữa.
  Widget _buildScanOverlay(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxWidth * 0.7;
        final top = (constraints.maxHeight - scanSize) / 2;
        final left = (constraints.maxWidth - scanSize) / 2;

        return Stack(
          children: [
            // Phần tối xung quanh
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    top: top,
                    left: left,
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // Bất kỳ màu nào (sẽ bị cut out)
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusLG,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Viền scan area
            Positioned(
              top: top,
              left: left,
              child: Container(
                width: scanSize,
                height: scanSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.7),
                    width: 2.5,
                  ),
                ),
              ),
            ),
            // Corner accents
            ..._buildCornerAccents(top, left, scanSize, colorScheme.primary),
          ],
        );
      },
    );
  }

  /// 4 góc accent sáng.
  List<Widget> _buildCornerAccents(
    double top,
    double left,
    double size,
    Color color,
  ) {
    const cornerLen = 30.0;
    const cornerWidth = 4.0;

    Widget corner({
      required double t,
      required double l,
      required BorderRadius br,
    }) {
      return Positioned(
        top: t,
        left: l,
        child: Container(
          width: cornerLen,
          height: cornerLen,
          decoration: BoxDecoration(
            border: Border(
              top: br.topLeft.x > 0 || br.topRight.x > 0
                  ? BorderSide(color: color, width: cornerWidth)
                  : BorderSide.none,
              bottom: br.bottomLeft.x > 0 || br.bottomRight.x > 0
                  ? BorderSide(color: color, width: cornerWidth)
                  : BorderSide.none,
              left: br.topLeft.x > 0 || br.bottomLeft.x > 0
                  ? BorderSide(color: color, width: cornerWidth)
                  : BorderSide.none,
              right: br.topRight.x > 0 || br.bottomRight.x > 0
                  ? BorderSide(color: color, width: cornerWidth)
                  : BorderSide.none,
            ),
            borderRadius: br,
          ),
        ),
      );
    }

    return [
      // Top-left
      corner(
        t: top,
        l: left,
        br: const BorderRadius.only(topLeft: Radius.circular(12)),
      ),
      // Top-right
      corner(
        t: top,
        l: left + size - cornerLen,
        br: const BorderRadius.only(topRight: Radius.circular(12)),
      ),
      // Bottom-left
      corner(
        t: top + size - cornerLen,
        l: left,
        br: const BorderRadius.only(bottomLeft: Radius.circular(12)),
      ),
      // Bottom-right
      corner(
        t: top + size - cornerLen,
        l: left + size - cornerLen,
        br: const BorderRadius.only(bottomRight: Radius.circular(12)),
      ),
    ];
  }

  Widget _buildTopBar(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: AppConstants.paddingMD,
      right: AppConstants.paddingMD,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Quét mã QR vé học sinh',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 42 + 12), // Balance
        ],
      ),
    );
  }

  Widget _buildBottomInfo(bool isDark, ColorScheme colorScheme) {
    return Positioned(
      left: AppConstants.paddingLG,
      right: AppConstants.paddingLG,
      bottom: MediaQuery.of(context).padding.bottom + AppConstants.paddingXL,
      child: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              margin: const EdgeInsets.only(bottom: AppConstants.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _errorMessage = null;
                        _hasScanned = false;
                      });
                    },
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            child: const Text(
              'Đưa camera hướng vào mã QR trên vé xe buýt của học sinh '
              'để tự động điểm danh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QR Detection ───

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _hasScanned = true);

    try {
      final data = jsonDecode(rawValue) as Map<String, dynamic>;
      final ticketId = data['ticketId'] as String?;

      if (ticketId == null || ticketId.isEmpty) {
        setState(() {
          _errorMessage = 'Mã QR không hợp lệ: thiếu thông tin vé';
          _hasScanned = false;
        });
        return;
      }

      // Trả ticketId về cho caller
      Navigator.pop(context, ticketId);
    } catch (e) {
      setState(() {
        _errorMessage = 'Mã QR không hợp lệ. Vui lòng thử lại.';
        _hasScanned = false;
      });
    }
  }
}
