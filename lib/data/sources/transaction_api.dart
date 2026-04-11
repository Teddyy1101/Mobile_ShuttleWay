import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/transaction_model.dart';

/// Data source giao tiếp trực tiếp với backend cho luồng Transaction.
class TransactionApi {
  final DioClient _dioClient;

  TransactionApi(this._dioClient);

  /// Gọi API POST /transactions/checkout.
  /// Tạo giao dịch thanh toán mới (trạng thái PENDING).
  /// [paymentMethod] — MOMO, SEPAY, VNPAY, CASH.
  Future<TransactionModel> checkout({
    required String ticketId,
    required String paymentMethod,
    String? promotionCode,
  }) async {
    try {
      final body = <String, dynamic>{
        'ticketId': ticketId,
        'paymentMethod': paymentMethod,
      };
      if (promotionCode != null) body['promotionCode'] = promotionCode;

      final response = await _dioClient.dio.post(
        '/transactions/checkout',
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        return TransactionModel.fromJson(result);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Checkout thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi checkout: $e');
    }
  }

  /// Gọi API GET /transactions/:id/momo-url.
  /// Trả về URL thanh toán MoMo để mở trong trình duyệt / WebView.
  Future<String> getMoMoUrl(String transactionId) async {
    try {
      final response = await _dioClient.dio.get(
        '/transactions/$transactionId/momo-url',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        return result['paymentUrl'] as String? ?? '';
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Lấy URL MoMo thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy URL MoMo: $e');
    }
  }

  /// Gọi API GET /transactions/:id/vnpay-url.
  /// Trả về URL thanh toán VNPay để mở trong trình duyệt / WebView.
  Future<String> getVnPayUrl(String transactionId) async {
    try {
      final response = await _dioClient.dio.get(
        '/transactions/$transactionId/vnpay-url',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        return result['paymentUrl'] as String? ?? '';
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Lấy URL VNPay thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy URL VNPay: $e');
    }
  }

  /// Gọi API GET /transactions/my-transactions.
  /// Trả về [TransactionListResponse] nếu thành công.
  Future<TransactionListResponse> getMyTransactions({
    int page = 1,
    int limit = 20,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (fromDate != null) queryParams['fromDate'] = fromDate;
      if (toDate != null) queryParams['toDate'] = toDate;

      final response = await _dioClient.dio.get(
        '/transactions/my-transactions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        final itemsList = result['data'] as List<dynamic>? ?? [];
        final meta = result['meta'] as Map<String, dynamic>? ?? {};

        return TransactionListResponse(
          items: itemsList
              .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList(),
          total: meta['total'] as int? ?? 0,
          page: meta['page'] as int? ?? 1,
          limit: meta['limit'] as int? ?? 20,
          totalPages: meta['totalPages'] as int? ?? 0,
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Lấy lịch sử giao dịch thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy lịch sử giao dịch: $e');
    }
  }

  /// Gọi API GET /transactions/:id/status.
  /// Kiểm tra trạng thái giao dịch (polling SePay).
  /// Trả về `PENDING`, `SUCCESS` hoặc `FAILED`.
  Future<String> checkTransactionStatus(String transactionId) async {
    try {
      final response = await _dioClient.dio.get(
        '/transactions/$transactionId/status',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        return result['status'] as String? ?? 'PENDING';
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Kiểm tra trạng thái thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi kiểm tra trạng thái: $e');
    }
  }

  /// Gọi API POST /transactions/:id/confirm-payment.
  /// Xác nhận kết quả thanh toán từ mobile sau khi WebView trả về.
  Future<void> confirmPayment({
    required String transactionId,
    String? responseCode,
    String? resultCode,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (responseCode != null) body['responseCode'] = responseCode;
      if (resultCode != null) body['resultCode'] = resultCode;

      await _dioClient.dio.post(
        '/transactions/$transactionId/confirm-payment',
        data: body,
      );
    } catch (e) {
      // Không throw — chỉ best-effort
      rethrow;
    }
  }
}
