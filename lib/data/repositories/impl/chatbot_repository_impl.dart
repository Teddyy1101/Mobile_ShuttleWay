import '../chatbot_repository.dart';
import '../../sources/chatbot_api.dart';

/// Implementation của [ChatbotRepository] sử dụng API.
class ApiChatbotRepository implements ChatbotRepository {
  final ChatbotApi _remoteSource;

  ApiChatbotRepository(this._remoteSource);

  @override
  Future<String> ask(
    String message,
    List<Map<String, String>> history,
  ) {
    return _remoteSource.ask(message: message, history: history);
  }
}
