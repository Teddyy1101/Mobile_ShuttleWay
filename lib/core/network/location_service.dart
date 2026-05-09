import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/trip_model.dart';
import 'socket_service.dart';

/// Khoảng cách tối thiểu (mét) để coi xe đã đến trạm.
const double kStationArrivalThresholdMeters = 50.0;

/// Khoảng cách tối thiểu giữa 2 lần emit socket (ms).
const int kEmitThrottleMs = 1000;

/// Service quản lý GPS thật từ thiết bị.
/// Đọc vị trí qua [Geolocator], emit tọa độ qua [SocketService],
/// và tự động detect khi xe đến gần trạm (≤ [kStationArrivalThresholdMeters]).
/// Trên Android: sử dụng Foreground Service có notification ghim
/// (thông qua [ForegroundNotificationConfig] của geolocator_android).
/// Trên iOS: sử dụng background location với indicator trên status bar.
class LocationService {
  StreamSubscription<Position>? _positionSub;
  bool _isTracking = false;
  String? _tripId;
  SocketService? _socketService;
  List<TripRouteStationModel> _stations = [];
  int _nextStationIdx = 0;
  DateTime _lastEmitTime = DateTime(2000);
  bool _stationDetectionPaused = false;

  /// Callback khi nhận vị trí mới từ GPS.
  void Function(double lat, double lng)? _onPositionChanged;

  /// Callback khi xe đến gần trạm (≤ threshold).
  void Function(int stationIndex, TripRouteStationModel station)?
      _onStationReached;

  /// GPS tracking đang hoạt động không.
  bool get isTracking => _isTracking;

  /// Kiểm tra và yêu cầu quyền truy cập vị trí.
  /// Trả về `true` nếu có quyền, `false` nếu bị từ chối.
  Future<bool> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services disabled');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permission denied forever');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[LocationService] Error requesting permission: $e');
      return false;
    }
  }

  /// Bắt đầu theo dõi GPS thật với Foreground Notification.
  ///
  /// [tripId] — ID chuyến đi để emit qua socket.
  /// [socketService] — Service socket để emit tọa độ.
  /// [stations] — Danh sách trạm đã sắp xếp theo chiều đi.
  /// [initialNextStationIdx] — Index trạm tiếp theo cần detect.
  /// [onPositionChanged] — Callback khi GPS cập nhật vị trí.
  /// [onStationReached] — Callback khi xe đến gần trạm.
  Future<void> startTracking({
    required String tripId,
    required SocketService socketService,
    required List<TripRouteStationModel> stations,
    required int initialNextStationIdx,
    required void Function(double lat, double lng) onPositionChanged,
    required void Function(int stationIndex, TripRouteStationModel station)
        onStationReached,
  }) async {
    // Dừng tracking cũ nếu có
    stopTracking();

    _tripId = tripId;
    _socketService = socketService;
    _stations = stations;
    _nextStationIdx = initialNextStationIdx;
    _onPositionChanged = onPositionChanged;
    _onStationReached = onStationReached;
    _isTracking = true;
    _stationDetectionPaused = false;

    // Cấu hình platform-specific location settings
    final LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        forceLocationManager: false,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'SafeWheels — Đang chạy xe',
          notificationText: 'Đang theo dõi vị trí xe buýt real-time',
          enableWakeLock: true,
          notificationIcon:
              AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _handlePosition,
      onError: (error) {
        debugPrint('[LocationService] GPS error: $error');
      },
    );

    debugPrint('[LocationService] ✓ GPS tracking started for trip: $tripId');
  }

  /// Xử lý mỗi vị trí GPS mới.
  void _handlePosition(Position position) {
    if (!_isTracking) return;

    final lat = position.latitude;
    final lng = position.longitude;

    // 1. Callback cập nhật UI
    _onPositionChanged?.call(lat, lng);

    // 2. Emit qua socket (throttle kEmitThrottleMs)
    final now = DateTime.now();
    if (now.difference(_lastEmitTime).inMilliseconds >= kEmitThrottleMs) {
      _lastEmitTime = now;
      if (_tripId != null) {
        _socketService?.emitLocation(_tripId!, lat, lng);
      }
    }

    // 3. Detect đến trạm
    if (!_stationDetectionPaused && _nextStationIdx < _stations.length) {
      final targetStation = _stations[_nextStationIdx];
      final distance = _haversineDistance(
        lat,
        lng,
        targetStation.station.latitude,
        targetStation.station.longitude,
      );

      if (distance <= kStationArrivalThresholdMeters) {
        // Pause detection để tránh trigger nhiều lần cho cùng trạm
        _stationDetectionPaused = true;
        final arrivedIdx = _nextStationIdx;
        _nextStationIdx++;
        _onStationReached?.call(arrivedIdx, targetStation);
      }
    }
  }

  /// Tạm dừng detect trạm (khi attendance sheet đang mở).
  void pauseStationDetection() {
    _stationDetectionPaused = true;
  }

  /// Tiếp tục detect trạm (sau khi đóng attendance sheet).
  void resumeStationDetection() {
    _stationDetectionPaused = false;
  }

  /// Dừng theo dõi GPS, hủy subscription, giải phóng tài nguyên.
  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _isTracking = false;
    _tripId = null;
    _socketService = null;
    _stations = [];
    _nextStationIdx = 0;
    _onPositionChanged = null;
    _onStationReached = null;
    _stationDetectionPaused = false;
    debugPrint('[LocationService] ✗ GPS tracking stopped');
  }

  /// Tính khoảng cách Haversine giữa 2 tọa độ (đơn vị: mét).
  double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0; // bán kính Trái Đất (mét)
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}
