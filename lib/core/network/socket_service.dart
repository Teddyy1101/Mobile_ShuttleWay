import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';

/// Service quản lý kết nối WebSocket (Socket.IO) cho tracking real-time.
/// Kết nối vào namespace `/tracking` trên backend.
class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  /// Trạng thái kết nối hiện tại.
  bool get isConnected => _isConnected;

  /// Khởi tạo kết nối Socket.IO vào namespace `/tracking`.
  /// Tự động gắn Bearer Token từ SharedPreferences.
  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    _socket = io.io(
      '${AppConstants.socketBaseUrl}/tracking',
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

  /// Tham gia theo dõi chuyến đi (join room theo tripId).
  void joinTrip(String tripId) {
    _socket?.emit('join_trip', {'tripId': tripId});
  }

  /// Lắng nghe sự kiện cập nhật vị trí xe buýt.
  /// Callback nhận [lat], [lng] mới.
  void onLocationUpdated(void Function(double lat, double lng) callback) {
    _socket?.on('location_updated', (data) {
      if (data is Map<String, dynamic>) {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          callback(lat, lng);
        }
      }
    });
  }

  /// Lắng nghe sự kiện hoàn thành giả lập.
  void onSimulationCompleted(void Function() callback) {
    _socket?.on('simulation_completed', (_) {
      callback();
    });
  }

  /// Rời khỏi room theo dõi chuyến đi.
  void leaveTrip(String tripId) {
    _socket?.emit('leave_trip', {'tripId': tripId});
  }

  /// Ngắt kết nối Socket.IO.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
