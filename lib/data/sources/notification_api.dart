import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationApi {
  final DioClient _dioClient;

  NotificationApi(this._dioClient);

  /// GET /notifications (phân trang).
  Future<({List<NotificationModel> data, int total, int totalPages})>
      getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final result = body['data'] as Map<String, dynamic>? ?? {};
        final items = result['data'] as List<dynamic>? ?? [];
        final meta = result['meta'] as Map<String, dynamic>? ?? {};

        return (
          data: items
              .map((e) =>
                  NotificationModel.fromJson(e as Map<String, dynamic>))
              .toList(),
          total: meta['total'] as int? ?? 0,
          totalPages: meta['totalPages'] as int? ?? 1,
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Lấy thông báo thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy thông báo: $e');
    }
  }

  /// PATCH /notifications/:id/read.
  Future<void> markAsRead(String id) async {
    try {
      final response = await _dioClient.dio.patch('/notifications/$id/read');

      if (response.statusCode == 200) return;

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Đánh dấu đã đọc thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi đánh dấu đã đọc: $e');
    }
  }

  /// PATCH /notifications/read-all.
  Future<void> markAllAsRead() async {
    try {
      final response = await _dioClient.dio.patch('/notifications/read-all');

      if (response.statusCode == 200) return;

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Đánh dấu tất cả đã đọc thất bại',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi đánh dấu tất cả đã đọc: $e');
    }
  }
}
