import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../data/models/promotion_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/promotion_repository.dart';

/// Controller quản lý state cho luồng thanh toán vé xe.
/// Sử dụng ChangeNotifier + ListenableBuilder pattern.
class PaymentController extends ChangeNotifier {
  final PaymentRepository _paymentRepository;
  final PromotionRepository _promotionRepository;

  PaymentController(this._paymentRepository, this._promotionRepository);

  // ─── State ────────────────────────────────────────────
  String _selectedMethod = 'MOMO';
  bool _isProcessing = false;
  String? _errorMessage;
  TransactionModel? _transaction;
  String? _paymentUrl;

  // ─── Promotion State ──────────────────────────────────
  List<PromotionModel> _promotions = [];
  bool _isLoadingPromotions = false;
  PromotionModel? _appliedPromotion;

  // ─── Polling State (SePay) ────────────────────────────
  Timer? _pollingTimer;
  bool _isPolling = false;
  int _pollingElapsedSeconds = 0;
  String? _pollingStatus;

  /// Tổng thời gian polling tối đa (giây).
  static const int pollingMaxSeconds = 600; // 10 phút

  /// Khoảng cách giữa mỗi lần polling (giây).
  static const int pollingIntervalSeconds = 5;

  String get selectedMethod => _selectedMethod;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  TransactionModel? get transaction => _transaction;
  String? get paymentUrl => _paymentUrl;

  List<PromotionModel> get promotions => _promotions;
  bool get isLoadingPromotions => _isLoadingPromotions;
  PromotionModel? get appliedPromotion => _appliedPromotion;

  bool get isPolling => _isPolling;
  String? get pollingStatus => _pollingStatus;

  /// Số giây còn lại trước khi hết hạn polling.
  int get pollingTimeRemaining =>
      (pollingMaxSeconds - _pollingElapsedSeconds).clamp(0, pollingMaxSeconds);

  /// Chọn phương thức thanh toán.
  void selectMethod(String method) {
    _selectedMethod = method;
    _errorMessage = null;
    notifyListeners();
  }

  /// Tải danh sách mã khuyến mãi đang có hiệu lực.
  Future<void> loadPromotions() async {
    _isLoadingPromotions = true;
    notifyListeners();

    try {
      _promotions = await _promotionRepository.getActivePromotions();
    } catch (_) {
      _promotions = [];
    }

    _isLoadingPromotions = false;
    notifyListeners();
  }

  /// Áp dụng mã khuyến mãi.
  void applyPromotion(PromotionModel promotion) {
    _appliedPromotion = promotion;
    _errorMessage = null;
    notifyListeners();
  }

  /// Hủy mã khuyến mãi đã áp dụng.
  void removePromotion() {
    _appliedPromotion = null;
    notifyListeners();
  }

  /// Tính số tiền sau khi áp dụng khuyến mãi.
  double calculateFinalAmount(double originalPrice) {
    if (_appliedPromotion == null) return originalPrice;
    final discount = _appliedPromotion!.calculateDiscount(originalPrice);
    return originalPrice - discount;
  }

  /// Thực hiện thanh toán: checkout → lấy URL hoặc QR tuỳ method.
  /// Trả về `true` nếu cần mở URL (MoMo/VNPay), `false` nếu SePay QR.
  Future<bool> processPayment(String ticketId) async {
    _isProcessing = true;
    _errorMessage = null;
    _paymentUrl = null;
    notifyListeners();

    try {
      // Bước 1: Tạo giao dịch thanh toán (trạng thái PENDING)
      _transaction = await _paymentRepository.checkout(
        ticketId: ticketId,
        paymentMethod: _selectedMethod,
        promotionCode: _appliedPromotion?.code,
      );

      // Bước 2: Xử lý theo phương thức
      switch (_selectedMethod) {
        case 'MOMO':
          _paymentUrl = await _paymentRepository.getMoMoUrl(_transaction!.id);
          _isProcessing = false;
          notifyListeners();
          return true; // Cần mở URL

        case 'VNPAY':
          _paymentUrl = await _paymentRepository.getVnPayUrl(_transaction!.id);
          _isProcessing = false;
          notifyListeners();
          return true; // Cần mở URL

        case 'SEPAY':
          // SePay: không cần mở URL, hiển thị QR trên UI
          _isProcessing = false;
          notifyListeners();
          return false; // Hiển thị QR

        default:
          _isProcessing = false;
          notifyListeners();
          return false;
      }
    } on DioException catch (e) {
      _isProcessing = false;
      _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Lỗi không xác định khi thanh toán';
      notifyListeners();
      return false;
    }
  }

  // ─── Polling Methods (SePay) ──────────────────────────

  /// Bắt đầu polling kiểm tra trạng thái giao dịch SePay.
  /// Gọi API mỗi [pollingIntervalSeconds] giây, tối đa [pollingMaxSeconds].
  /// Khi phát hiện SUCCESS hoặc FAILED → dừng polling + gọi [onResult].
  void startPolling(String transactionId, {VoidCallback? onResult}) {
    stopPolling();

    _isPolling = true;
    _pollingElapsedSeconds = 0;
    _pollingStatus = 'PENDING';
    notifyListeners();

    _pollingTimer = Timer.periodic(
      const Duration(seconds: pollingIntervalSeconds),
      (_) async {
        _pollingElapsedSeconds += pollingIntervalSeconds;

        // Hết thời gian → dừng polling
        if (_pollingElapsedSeconds >= pollingMaxSeconds) {
          _pollingStatus = 'TIMEOUT';
          stopPolling();
          onResult?.call();
          return;
        }

        try {
          final status =
              await _paymentRepository.checkTransactionStatus(transactionId);

          if (status == 'SUCCESS' || status == 'FAILED') {
            _pollingStatus = status;
            stopPolling();
            onResult?.call();
          } else {
            // Vẫn PENDING → cập nhật UI (countdown)
            notifyListeners();
          }
        } catch (_) {
          // Lỗi mạng: bỏ qua, tiếp tục polling
          notifyListeners();
        }
      },
    );
  }

  /// Dừng polling và dọn dẹp timer.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    notifyListeners();
  }

  /// Reset trạng thái cho lần thanh toán mới.
  void reset() {
    stopPolling();
    _selectedMethod = 'MOMO';
    _isProcessing = false;
    _errorMessage = null;
    _transaction = null;
    _paymentUrl = null;
    _appliedPromotion = null;
    _pollingStatus = null;
    _pollingElapsedSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  /// Xử lý lỗi chung từ Dio.
  void _handleDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      _errorMessage = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      _errorMessage = 'Không thể kết nối đến server. Vui lòng thử lại';
    } else {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        final msg = data['message'];
        if (msg is List) {
          _errorMessage = msg.join(', ');
        } else {
          _errorMessage = msg?.toString() ?? 'Đã xảy ra lỗi';
        }
      } else {
        _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại';
      }
    }
  }
}
