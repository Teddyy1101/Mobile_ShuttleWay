import '../../core/network/dio_client.dart';

/// Data source giao tiếp với backend cho luồng Chatbot AI.
class ChatbotApi {
  final DioClient _dioClient;

  ChatbotApi(this._dioClient);

  /// Gọi API POST /chatbot/ask.
  /// Gửi tin nhắn hiện tại và lịch sử hội thoại, nhận phản hồi từ AI.
  ///
  /// Response format (đã qua TransformInterceptor):
  /// ```json
  /// { "statusCode": 201, "message": "...", "data": { "reply": "..." } }
  /// ```
  Future<String> ask({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final response = await _dioClient.dio.post(
      '/chatbot/ask',
      data: {
        'message': message,
        'history': history,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        // TransformInterceptor wraps response: { statusCode, message, data }
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final reply = data['reply'];
          if (reply is String && reply.isNotEmpty) {
            return reply;
          }
        }
      }
      return 'Xin lỗi, hệ thống không thể trả lời lúc này. Vui lòng thử lại sau.';
    }

    throw Exception(
      'Gửi tin nhắn thất bại (status: ${response.statusCode})',
    );
  }
}
