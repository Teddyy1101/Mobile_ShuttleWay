/// Interface repository cho phiếu hỗ trợ.
abstract class SupportRepository {
  /// Tạo phiếu yêu cầu hỗ trợ mới.
  Future<Map<String, dynamic>> createTicket({
    required String userId,
    required String category,
    required String title,
    required String content,
  });
}
