import '../support_repository.dart';
import '../../sources/support_ticket_api.dart';

class ApiSupportRepository implements SupportRepository {
  final SupportTicketApi _api;

  ApiSupportRepository(this._api);

  @override
  Future<Map<String, dynamic>> createTicket({
    required String userId,
    required String category,
    required String title,
    required String content,
  }) {
    return _api.createSupportTicket(
      userId: userId,
      category: category,
      title: title,
      content: content,
    );
  }
}
