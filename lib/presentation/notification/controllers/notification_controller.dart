import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

/// Controller quản lý state cho trang Thông báo.
/// Sử dụng ChangeNotifier + ListenableBuilder pattern.
class NotificationController extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationController(this._repository);

  // State 
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;
  bool get hasMore => _currentPage < _totalPages;

  /// Thông báo hôm nay.
  List<NotificationModel> get todayNotifications {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _notifications
        .where((n) => n.createdAt.toLocal().isAfter(todayStart))
        .toList();
  }

  /// Thông báo hôm qua.
  List<NotificationModel> get yesterdayNotifications {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    return _notifications
        .where((n) =>
            n.createdAt.toLocal().isAfter(yesterdayStart) &&
            n.createdAt.toLocal().isBefore(todayStart))
        .toList();
  }

  /// Thông báo cũ hơn (trước hôm qua).
  List<NotificationModel> get olderNotifications {
    final now = DateTime.now();
    final yesterdayStart =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    return _notifications
        .where((n) => n.createdAt.toLocal().isBefore(yesterdayStart))
        .toList();
  }

  /// Load danh sách thông báo (page 1).
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _totalPages = 1;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getNotifications(
        page: 1,
        limit: 20,
      );
      _notifications = result.notifications;
      _totalPages = result.totalPages;
      _currentPage = 1;
      _recalculateUnreadCount();
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _parseDioError(e);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
    }
  }

  /// Load thêm trang tiếp theo (infinite scroll).
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await _repository.getNotifications(
        page: nextPage,
        limit: 20,
      );
      _notifications.addAll(result.notifications);
      _totalPages = result.totalPages;
      _currentPage = nextPage;
      _recalculateUnreadCount();
      _isLoadingMore = false;
      notifyListeners();
    } on DioException {
      _isLoadingMore = false;
      notifyListeners();
    } catch (_) {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Đánh dấu một thông báo đã đọc.
  Future<void> markAsRead(String id) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    _notifications[index] = _notifications[index].copyWithRead();
    _recalculateUnreadCount();
    notifyListeners();

    try {
      await _repository.markAsRead(id);
    } catch (e) {
      // Rollback nếu lỗi — reload lại
      await loadNotifications(refresh: true);
    }
  }

  /// Đánh dấu tất cả thông báo đã đọc.
  Future<void> markAllAsRead() async {
    // Optimistic update
    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWithRead())
        .toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _repository.markAllAsRead();
    } catch (e) {
      // Rollback nếu lỗi — reload lại
      await loadNotifications(refresh: true);
    }
  }

  /// Khi nhận thông báo mới từ Socket.IO → chèn vào đầu danh sách.
  void onNewNotificationReceived(NotificationModel notification) {
    _notifications.insert(0, notification);
    _recalculateUnreadCount();
    notifyListeners();
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Private Helpers ──────────────────────────────────

  void _recalculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
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
