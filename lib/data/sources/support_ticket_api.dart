import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class SupportTicketApi {
  final DioClient _dioClient;

  SupportTicketApi(this._dioClient);

  Future<Map<String, dynamic>> createSupportTicket({
    required String userId,
    required String category,
    required String title,
    required String content,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/support-tickets',
        data: {
          'userId': userId,
          'category': category,
          'title': title,
          'content': content,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>? ?? data;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Gửi phiếu hỗ trợ thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi gửi phiếu hỗ trợ: $e');
    }
  }
}
