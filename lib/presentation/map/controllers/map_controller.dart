import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/utils/polyline_decoder.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/repositories/trip_repository.dart';

class MapController extends ChangeNotifier {
  final TripRepository _tripRepository;
  final SocketService _socketService;

  MapController(this._tripRepository, this._socketService);

  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<TripModel> _activeTrips = [];
  TripModel? _selectedTrip;
  LatLng? _currentBusPosition;
  List<LatLng> _polylinePoints = [];
  List<TripRouteStationModel> _orderedStations = [];
  String? _currentTripId;
  String? _selectedStudentId;

  DateTime? _lastSocketLocationTime;

  /// Timer cho discovery (tìm chuyến mới) hoặc tracking (theo dõi trạm).
  Timer? _pollingTimer;

  Timer? _animationTimer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TripModel> get activeTrips => _activeTrips;
  TripModel? get selectedTrip => _selectedTrip;
  LatLng? get currentBusPosition => _currentBusPosition;
  List<LatLng> get polylinePoints => _polylinePoints;
  List<TripRouteStationModel> get orderedStations => _orderedStations;
  String? get selectedStudentId => _selectedStudentId;

  /// Có chuyến đi đang hoạt động không.
  bool get hasActiveTrip => _selectedTrip != null;

  /// Discovery hoặc tracking polling đang chạy không.
  bool get isPollingActive => _pollingTimer != null;

  /// Trạm hiện tại (index) của xe buýt.
  int get currentStationIndex => _selectedTrip?.currentStation ?? 0;

  /// Load danh sách chuyến đi đang hoạt động.
  /// Nếu tìm thấy → join socket + bắt đầu tracking polling.
  /// Nếu không → bắt đầu discovery polling (tìm chuyến mới mỗi 5s).
  Future<void> loadActiveTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeTrips = await _tripRepository.getMyActiveTrips();

      if (_activeTrips.isNotEmpty) {
        await selectTrip(_activeTrips.first);
        _startTrackingPolling(_activeTrips.first.id);
      } else {
        _clearTripState();
        _startDiscoveryPolling();
      }

      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
      _startDiscoveryPolling();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
      _startDiscoveryPolling();
    }
  }

  /// Load chuyến active cho một học sinh cụ thể (dành cho PARENT).
  Future<void> selectStudentTrip(String studentId) async {
    _selectedStudentId = studentId;

    if (_activeTrips.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        _activeTrips = await _tripRepository.getMyActiveTrips();
      } on DioException catch (e) {
        _isLoading = false;
        _handleDioError(e);
        notifyListeners();
        return;
      } catch (e) {
        _isLoading = false;
        _errorMessage = 'Đã xảy ra lỗi không xác định';
        notifyListeners();
        return;
      }
    }

    if (_activeTrips.isNotEmpty) {
      await selectTrip(_activeTrips.first);
    } else {
      _clearTripState();
      _startDiscoveryPolling();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Chọn và hiển thị một chuyến đi cụ thể.
  Future<void> selectTrip(TripModel trip) async {
    _stopPolling();
    if (_currentTripId != null && _currentTripId != trip.id) {
      _socketService.leaveTrip(_currentTripId!);
    }

    _selectedTrip = trip;
    _currentTripId = trip.id;

    // Xử lý polyline và stations theo chiều
    _processRouteData(trip);

    // Đặt vị trí xe ban đầu tại trạm hiện tại hoặc trạm đầu tiên
    _updateBusPositionFromStation(trip.currentStation);

    // Kết nối WebSocket và join room
    await _connectAndJoinTrip(trip.id);

    // Bắt đầu tracking polling
    _startTrackingPolling(trip.id);

    notifyListeners();
  }

  /// Xử lý dữ liệu tuyến: decode polyline, sắp xếp trạm theo chiều.
  void _processRouteData(TripModel trip) {
    final route = trip.route;
    if (route == null) return;

    final stations = List<TripRouteStationModel>.from(route.stations);
    if (trip.isDropOff) {
      stations.sort((a, b) => b.orderIndex.compareTo(a.orderIndex));
    } else {
      stations.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }
    _orderedStations = stations;

    if (route.encodedPolyline != null &&
        route.encodedPolyline!.isNotEmpty) {
      _polylinePoints = PolylineDecoder.decode(route.encodedPolyline);
      if (trip.isDropOff) {
        _polylinePoints = _polylinePoints.reversed.toList();
      }
    } else {
      _polylinePoints = _orderedStations
          .map((s) => LatLng(s.station.latitude, s.station.longitude))
          .toList();
    }
  }

  /// Cập nhật vị trí bus từ station index.
  void _updateBusPositionFromStation(int stationIndex) {
    if (_orderedStations.isNotEmpty) {
      _animationTimer?.cancel();
      final idx = stationIndex.clamp(0, _orderedStations.length - 1);
      final station = _orderedStations[idx].station;
      _currentBusPosition = LatLng(station.latitude, station.longitude);
    }
  }

  /// Kết nối Socket.IO và join room tracking.
  Future<void> _connectAndJoinTrip(String tripId) async {
    try {
      // Đăng ký callbacks trước khi connect (SocketService lưu lại)
      _socketService.onLocationUpdated(_onLocationUpdated);
      _socketService.onSimulationCompleted(_onSimulationCompleted);

      await _socketService.connect();
      _socketService.joinTrip(tripId);
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
    }
  }

  /// Callback khi nhận tọa độ mới từ WebSocket.
  void _onLocationUpdated(double lat, double lng) {
    _lastSocketLocationTime = DateTime.now();
    final receivedPos = LatLng(lat, lng);

    // Nếu có polyline → snap vị trí lên polyline gần nhất
    // để icon di chuyển mượt trên đường thay vì nhảy ngoài đường
    final targetPos = _polylinePoints.length >= 2 ? _snapToPolyline(receivedPos) : receivedPos;

    if (_currentBusPosition == null) {
      _currentBusPosition = targetPos;
      notifyListeners();
      return;
    }

    _animateBusTo(targetPos);
  }

  void _animateBusTo(LatLng targetPos) {
    final startPos = _currentBusPosition!;
    final startTime = DateTime.now();
    // Animation duration 500ms
    const duration = Duration(milliseconds: 500);

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      final now = DateTime.now();
      final elapsed = now.difference(startTime);

      if (elapsed >= duration) {
        _currentBusPosition = targetPos;
        notifyListeners();
        timer.cancel();
        return;
      }

      final t = elapsed.inMilliseconds / duration.inMilliseconds;
      // Linear interpolation
      final currentLat = startPos.latitude + (targetPos.latitude - startPos.latitude) * t;
      final currentLng = startPos.longitude + (targetPos.longitude - startPos.longitude) * t;
      
      _currentBusPosition = LatLng(currentLat, currentLng);
      notifyListeners();
    });
  }

  /// Snap một vị trí lên điểm gần nhất trên polyline.
  LatLng _snapToPolyline(LatLng pos) {
    if (_polylinePoints.isEmpty) return pos;

    double minDist = double.infinity;
    LatLng closest = pos;

    for (int i = 0; i < _polylinePoints.length - 1; i++) {
      final projected = _projectOnSegment(
        pos, _polylinePoints[i], _polylinePoints[i + 1],
      );
      final dx = projected.latitude - pos.latitude;
      final dy = projected.longitude - pos.longitude;
      final d = dx * dx + dy * dy;
      if (d < minDist) {
        minDist = d;
        closest = projected;
      }
    }

    return closest;
  }

  /// Chiếu điểm P lên đoạn thẳng AB, trả về điểm gần nhất trên đoạn.
  LatLng _projectOnSegment(LatLng p, LatLng a, LatLng b) {
    final dx = b.latitude - a.latitude;
    final dy = b.longitude - a.longitude;
    if (dx == 0 && dy == 0) return a;

    var t = ((p.latitude - a.latitude) * dx + (p.longitude - a.longitude) * dy) /
        (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);

    return LatLng(
      a.latitude + t * dx,
      a.longitude + t * dy,
    );
  }

  /// Callback khi giả lập hoàn thành.
  void _onSimulationCompleted() {
    _clearTripState();
    notifyListeners();
    _startDiscoveryPolling();
  }

  /// Dừng mọi polling timer.
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _animationTimer?.cancel();
    _animationTimer = null;
  }

  /// Discovery polling — tìm chuyến active mới mỗi 5 giây.
  void _startDiscoveryPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollDiscovery(),
    );
  }

  /// Poll API để phát hiện chuyến mới.
  Future<void> _pollDiscovery() async {
    try {
      final trips = await _tripRepository.getMyActiveTrips();

      if (trips.isNotEmpty) {
        _activeTrips = trips;
        _stopPolling();
        await selectTrip(trips.first);
        _startTrackingPolling(trips.first.id);
        notifyListeners();
      }
    } catch (_) {
      // Bỏ qua lỗi discovery — sẽ thử lại lần sau
    }
  }

  /// Tracking polling — cập nhật currentStation + busPosition mỗi 5 giây.
  void _startTrackingPolling(String tripId) {
    _stopPolling();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollTripTracking(tripId),
    );
  }

  /// Poll server để lấy currentStation mới nhất + cập nhật vị trí bus.
  Future<void> _pollTripTracking(String tripId) async {
    try {
      final updatedTrip = await _tripRepository.getTripTracking(tripId);

      // Cập nhật currentStation nếu thay đổi
      if (_selectedTrip != null &&
          updatedTrip.currentStation != _selectedTrip!.currentStation) {
        _selectedTrip = updatedTrip;

        // Chỉ snap vị trí bus về trạm khi KHÔNG có socket location gần đây.
        // Nếu socket đang hoạt động (< 3 giây), vị trí bus đã được cập nhật
        // liên tục theo tọa độ thực → không cần ghi đè.
        final now = DateTime.now();
        final hasRecentSocket = _lastSocketLocationTime != null &&
            now.difference(_lastSocketLocationTime!).inSeconds < 3;

        if (!hasRecentSocket) {
          _updateBusPositionFromStation(updatedTrip.currentStation);
        }

        notifyListeners();
      }

      // Nếu chuyến đã hoàn thành → dừng tracking, chuyển discovery
      if (updatedTrip.status == 'COMPLETED') {
        _clearTripState();
        notifyListeners();
        _startDiscoveryPolling();
      }
    } catch (_) {
      // Bỏ qua lỗi polling — không ảnh hưởng UX
    }
  }


  /// Xóa state chuyến đi hiện tại.
  void _clearTripState() {
    if (_currentTripId != null) {
      _socketService.leaveTrip(_currentTripId!);
    }
    _selectedTrip = null;
    _currentTripId = null;
    _polylinePoints = [];
    _orderedStations = [];
    _currentBusPosition = null;
    _activeTrips = [];
    _stopPolling();
  }

  /// Tính toán trung tâm bản đồ từ tất cả các trạm.
  LatLng get mapCenter {
    if (_currentBusPosition != null) return _currentBusPosition!;
    if (_orderedStations.isEmpty) {
      return const LatLng(21.0285, 105.8542); // Hà Nội mặc định
    }

    double sumLat = 0;
    double sumLng = 0;
    for (final s in _orderedStations) {
      sumLat += s.station.latitude;
      sumLng += s.station.longitude;
    }
    return LatLng(
      sumLat / _orderedStations.length,
      sumLng / _orderedStations.length,
    );
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Dọn dẹp khi dispose.
  @override
  void dispose() {
    _stopPolling();
    if (_currentTripId != null) {
      _socketService.leaveTrip(_currentTripId!);
    }
    _socketService.disconnect();
    super.dispose();
  }

  /// Xử lý lỗi chung từ Dio.
  void _handleDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      _errorMessage = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      _errorMessage = 'Không thể kết nối đến server. Vui lòng thử lại';
    } else {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        final msg = data['message'];
        if (msg is List) {
          _errorMessage = msg.join(', ');
        } else {
          _errorMessage = msg?.toString() ?? 'Đã xảy ra lỗi';
        }
      } else {
        _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại';
      }
    }
  }
}
