import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';


class NotificationSocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  /// Trạng thái kết nối hiện tại.
  bool get isConnected => _isConnected;

  /// Khởi tạo kết nối Socket.IO vào namespace notifications.
  /// Tự động gắn Bearer Token từ SharedPreferences.
  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    _socket = io.io(
      '${AppConstants.socketBaseUrl}/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.onConnectError((data) {
      _isConnected = false;
    });

    _socket!.connect();
  }

  /// Tham gia room thông báo theo userId.
  void joinNotifications(String userId) {
    _socket?.emit('join_notifications', {'userId': userId});
  }

  /// Lắng nghe sự kiện thông báo mới từ backend.
  void onNewNotification(
    void Function(Map<String, dynamic> data) callback,
  ) {
    _socket?.on('new_notification', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Ngắt kết nối Socket.IO.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
