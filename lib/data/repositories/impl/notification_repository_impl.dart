import '../notification_repository.dart';
import '../../models/notification_model.dart';
import '../../sources/notification_api.dart';

class ApiNotificationRepository implements NotificationRepository {
  final NotificationApi _remoteSource;

  ApiNotificationRepository(this._remoteSource);

  @override
  Future<({List<NotificationModel> notifications, int total, int totalPages})>
      getNotifications({int page = 1, int limit = 20}) async {
    final result = await _remoteSource.getNotifications(
      page: page,
      limit: limit,
    );

    return (
      notifications: result.data,
      total: result.total,
      totalPages: result.totalPages,
    );
  }

  @override
  Future<void> markAsRead(String id) {
    return _remoteSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() {
    return _remoteSource.markAllAsRead();
  }

  @override
  Future<void> deleteAll() {
    return _remoteSource.deleteAll();
  }
}
