import '../models/transaction_model.dart';

/// Interface (Abstract class) cho Payment Repository.
/// Tất cả các tầng trên (Controller/Bloc) chỉ gọi qua interface này
/// để tuân thủ Dependency Inversion Principle.
abstract class PaymentRepository {
  /// Tạo giao dịch thanh toán (checkout).
  /// [paymentMethod] — MOMO, SEPAY, VNPAY, CASH.
  Future<TransactionModel> checkout({
    required String ticketId,
    required String paymentMethod,
    String? promotionCode,
  });

  /// Lấy URL thanh toán MoMo.
  Future<String> getMoMoUrl(String transactionId);

  /// Lấy URL thanh toán VNPay.
  Future<String> getVnPayUrl(String transactionId);

  /// Kiểm tra trạng thái giao dịch (polling SePay).
  /// Trả về `PENDING`, `SUCCESS` hoặc `FAILED`.
  Future<String> checkTransactionStatus(String transactionId);

  /// Xác nhận thanh toán từ mobile (sau khi WebView trả kết quả).
  Future<void> confirmPayment({
    required String transactionId,
    String? responseCode,
    String? resultCode,
  });
}
