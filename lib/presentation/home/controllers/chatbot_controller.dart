import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/chatbot_repository.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

/// Controller quản lý state cho màn hình Chatbot AI.
/// Lịch sử hội thoại lưu session-based (reset khi dispose).
/// Sliding window: giữ tối đa 10 cặp tin nhắn gần nhất khi gửi API.
class ChatbotController extends ChangeNotifier {
  final ChatbotRepository _repository;

  /// Số cặp tin nhắn tối đa gửi lên API (1 cặp = 1 user + 1 model).
  static const int _maxHistoryPairs = 10;
  ChatbotController(this._repository);

  // State 
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Gửi tin nhắn mới tới Chatbot AI.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Thêm tin nhắn user vào danh sách
    _messages.add(ChatMessage(
      content: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Xây dựng history (sliding window)
      final history = _buildHistory();
      final reply = await _repository.ask(trimmed, history);

      // Thêm tin nhắn AI vào danh sách
      _messages.add(ChatMessage(
        content: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _parseDioError(e);

      // Thêm tin nhắn lỗi từ AI
      _messages.add(ChatMessage(
        content: 'Xin lỗi, tôi không thể trả lời lúc này. '
            'Vui lòng thử lại sau.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';

      _messages.add(ChatMessage(
        content: 'Xin lỗi, đã xảy ra lỗi. Vui lòng thử lại sau.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  /// Reset phiên hội thoại — gọi khi user rời khỏi màn hình.
  void resetSession() {
    _messages.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private Helpers

  /// Xây dựng mảng history gửi lên API.
  /// Không bao gồm tin nhắn cuối cùng (vì đó là tin nhắn hiện tại).
  List<Map<String, String>> _buildHistory() {
    // Lấy tất cả tin nhắn trước tin nhắn cuối (tin nhắn cuối là message hiện tại)
    final previousMessages =
        _messages.length > 1 ? _messages.sublist(0, _messages.length - 1) : [];

    // Giới hạn sliding window: tối đa _maxHistoryPairs * 2 tin nhắn
    final maxMessages = _maxHistoryPairs * 2;
    final startIndex = previousMessages.length > maxMessages
        ? previousMessages.length - maxMessages
        : 0;
    final windowedMessages = previousMessages.sublist(startIndex);

    return windowedMessages
        .map((msg) => <String, String>{
              'role': msg.isUser ? 'user' : 'model',
              'content': msg.content,
            })
        .toList();
  }

  String _parseDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Không thể kết nối đến server. Vui lòng thử lại';
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      final msg = data['message'];
      if (msg is List) return msg.join(', ');
      return msg?.toString() ?? 'Đã xảy ra lỗi';
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại';
  }
}
