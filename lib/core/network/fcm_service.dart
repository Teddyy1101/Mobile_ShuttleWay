import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/dio_client.dart';

/// Top-level handler cho FCM background messages.
/// Phải là top-level function (không nằm trong class).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background Message: ${message.notification?.title}');
}

/// Service quản lý Firebase Cloud Messaging.
/// Gửi token lên backend, lắng nghe foreground messages,
/// hiển thị heads-up notification khi app đang mở.
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Kênh thông báo Android với độ ưu tiên cao nhất.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'safewheels_high_importance',
    'Thông báo quan trọng',
    description: 'Kênh thông báo ưu tiên cao cho SafeWheels',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Khởi tạo FCM: request permission, tạo notification channel,
  /// setup foreground handler hiển thị heads-up.
  Future<void> initialize() async {
    // Request quyền thông báo (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM Permission: ${settings.authorizationStatus}');

    // Đăng ký background handler
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // Cho phép hiển thị thông báo khi app ở foreground (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Tạo notification channel trên Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Khởi tạo flutter_local_notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings: initSettings);

    // Foreground: bắt FCM message → hiển thị heads-up notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Xử lý FCM message khi app đang mở (foreground).
  /// Dùng flutter_local_notifications để hiển thị heads-up popup.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? '';
    final body = notification.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  /// Lấy FCM token hiện tại.
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('Lỗi lấy FCM Token: $e');
      return null;
    }
  }

  /// Gửi FCM token lên backend qua PATCH /users/me.
  Future<void> registerToken(DioClient dioClient) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return;

      await dioClient.dio.patch(
        '/users/me',
        data: {'fcmToken': token},
      );
      debugPrint('FCM Token đã gửi lên server thành công');
    } catch (e) {
      debugPrint('Lỗi gửi FCM Token lên server: $e');
    }
  }

  /// Lắng nghe foreground messages (callback bổ sung cho controller).
  void onForegroundMessage(
    void Function(String title, String body) callback,
  ) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      if (title.isNotEmpty || body.isNotEmpty) {
        callback(title, body);
      }
    });
  }

  /// Lắng nghe khi user tap vào notification từ system tray.
  void onMessageOpenedApp(void Function(RemoteMessage) callback) {
    FirebaseMessaging.onMessageOpenedApp.listen(callback);
  }

  /// Lắng nghe token refresh (khi FCM token thay đổi).
  void onTokenRefresh(void Function(String token) callback) {
    _messaging.onTokenRefresh.listen(callback);
  }
}
