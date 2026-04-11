import '../models/notification_model.dart';

/// Interface (Abstract class) cho Notification Repository.
abstract class NotificationRepository {
  /// Lấy danh sách thông báo (phân trang).
  Future<({List<NotificationModel> notifications, int total, int totalPages})>
      getNotifications({int page = 1, int limit = 20});

  /// Đánh dấu một thông báo đã đọc.
  Future<void> markAsRead(String id);

  /// Đánh dấu tất cả thông báo đã đọc.
  Future<void> markAllAsRead();
}
