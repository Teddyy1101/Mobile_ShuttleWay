import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';

/// Service quản lý kết nối WebSocket (Socket.IO) cho tracking real-time.
/// Kết nối vào namespace `/tracking` trên backend.
class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  /// Completer để await kết nối thực sự.
  Completer<void>? _connectCompleter;

  /// TripId đang theo dõi — để tự động re-join khi reconnect.
  String? _currentTripId;

  /// Lưu callbacks để re-register khi reconnect.
  void Function(double lat, double lng)? _locationCallback;
  void Function()? _simulationCompletedCallback;

  /// Trạng thái kết nối hiện tại.
  bool get isConnected => _isConnected;

  /// Khởi tạo kết nối Socket.IO vào namespace `/tracking`.
  /// Tự động gắn Bearer Token từ SharedPreferences.
  /// **Await hàm này để đảm bảo socket đã connected trước khi emit.**
  Future<void> connect() async {
    // Đã kết nối rồi → return ngay
    if (_socket != null && _isConnected) return;

    // Đang trong quá trình kết nối → await completer hiện tại
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      return _connectCompleter!.future;
    }

    // Nếu socket tồn tại nhưng chưa connected → thử reconnect
    if (_socket != null && !_isConnected) {
      _connectCompleter = Completer<void>();
      _socket!.connect();
      await _connectCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
            _connectCompleter!.complete();
          }
        },
      );
      return;
    }

    _connectCompleter = Completer<void>();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    _socket = io.io(
      '${AppConstants.socketBaseUrl}/tracking',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() // Tắt auto-connect để control flow
          .enableReconnection()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[SocketService] ✓ Connected to /tracking');
      _isConnected = true;
      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        _connectCompleter!.complete();
      }
      // Re-join room nếu đã có tripId (handling reconnect)
      if (_currentTripId != null) {
        _socket?.emit('join_trip', {'tripId': _currentTripId});
      }
      // Re-register event listeners sau reconnect
      _registerEventListeners();
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] ✗ Disconnected');
      _isConnected = false;
    });

    _socket!.onReconnect((_) {
      debugPrint('[SocketService] ↻ Reconnected');
    });

    _socket!.onConnectError((data) {
      debugPrint('[SocketService] ✗ Connect error: $data');
      _isConnected = false;
      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        _connectCompleter!.complete();
      }
    });

    // Đăng ký listeners trước khi connect
    _registerEventListeners();

    _socket!.connect();

    // Timeout 5 giây
    await _connectCompleter!.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
          _connectCompleter!.complete();
        }
      },
    );
  }

  /// Đăng ký event listeners trên socket hiện tại.
  void _registerEventListeners() {
    if (_socket == null) return;

    // Location updated
    _socket!.off('location_updated');
    if (_locationCallback != null) {
      final callback = _locationCallback!;
      _socket!.on('location_updated', (data) {
        if (data is Map<String, dynamic>) {
          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            callback(lat, lng);
          }
        }
      });
    }

    // Simulation completed
    _socket!.off('simulation_completed');
    if (_simulationCompletedCallback != null) {
      final callback = _simulationCompletedCallback!;
      _socket!.on('simulation_completed', (_) {
        callback();
      });
    }
  }

  /// Tham gia theo dõi chuyến đi (join room theo tripId).
  void joinTrip(String tripId) {
    _currentTripId = tripId;
    if (_isConnected && _socket != null) {
      _socket!.emit('join_trip', {'tripId': tripId});
    }
  }

  /// Đăng ký callback cập nhật vị trí từ WebSocket.
  void onLocationUpdated(void Function(double lat, double lng) callback) {
    _locationCallback = callback;
    _registerEventListeners();
  }

  /// Đăng ký callback hoàn thành giả lập.
  void onSimulationCompleted(void Function() callback) {
    _simulationCompletedCallback = callback;
    _registerEventListeners();
  }

  /// Tài xế gửi cập nhật vị trí qua socket.
  void emitLocation(String tripId, double lat, double lng) {
    if (_socket != null && _isConnected) {
      _socket!.emit('update_location', {
        'tripId': tripId,
        'lat': lat,
        'lng': lng,
      });
    }
  }

  /// Rời khỏi room theo dõi chuyến đi.
  void leaveTrip(String tripId) {
    _socket?.emit('leave_trip', {'tripId': tripId});
    if (_currentTripId == tripId) {
      _currentTripId = null;
    }
  }

  /// Ngắt kết nối Socket.IO.
  void disconnect() {
    _currentTripId = null;
    _locationCallback = null;
    _simulationCompletedCallback = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectCompleter = null;
  }
}
