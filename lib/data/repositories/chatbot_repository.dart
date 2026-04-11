/// Interface (Abstract class) cho Chatbot Repository.
abstract class ChatbotRepository {
  /// Gửi tin nhắn tới Chatbot AI và nhận phản hồi.
  /// [message] — tin nhắn hiện tại của user.
  /// [history] — lịch sử hội thoại (role + content).
  Future<String> ask(String message, List<Map<String, String>> history);
}
