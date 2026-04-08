import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/utils/polyline_decoder.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/repositories/trip_repository.dart';

/// Controller quản lý state cho màn hình bản đồ theo dõi xe buýt.
/// Sử dụng ChangeNotifier + ListenableBuilder pattern.
class MapController extends ChangeNotifier {
  final TripRepository _tripRepository;
  final SocketService _socketService;

  MapController(this._tripRepository, this._socketService);

  // ─── State ────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  List<TripModel> _activeTrips = [];
  TripModel? _selectedTrip;
  LatLng? _currentBusPosition;
  List<LatLng> _polylinePoints = [];
  List<TripRouteStationModel> _orderedStations = [];
  String? _currentTripId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TripModel> get activeTrips => _activeTrips;
  TripModel? get selectedTrip => _selectedTrip;
  LatLng? get currentBusPosition => _currentBusPosition;
  List<LatLng> get polylinePoints => _polylinePoints;
  List<TripRouteStationModel> get orderedStations => _orderedStations;

  /// Có chuyến đi đang hoạt động không.
  bool get hasActiveTrip => _selectedTrip != null;

  /// Trạm hiện tại (index) của xe buýt.
  int get currentStationIndex => _selectedTrip?.currentStation ?? 0;

  /// Load danh sách chuyến đi đang hoạt động.
  Future<void> loadActiveTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeTrips = await _tripRepository.getMyActiveTrips();

      // Tự động chọn chuyến đầu tiên nếu có
      if (_activeTrips.isNotEmpty) {
        await selectTrip(_activeTrips.first);
      } else {
        _selectedTrip = null;
        _polylinePoints = [];
        _orderedStations = [];
        _currentBusPosition = null;
      }

      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
    }
  }

  /// Chọn và hiển thị một chuyến đi cụ thể.
  Future<void> selectTrip(TripModel trip) async {
    // Ngắt kết nối chuyến cũ nếu có
    if (_currentTripId != null) {
      _socketService.leaveTrip(_currentTripId!);
    }

    _selectedTrip = trip;
    _currentTripId = trip.id;

    // Xử lý polyline và stations theo chiều
    _processRouteData(trip);

    // Đặt vị trí xe ban đầu tại trạm đầu tiên
    if (_orderedStations.isNotEmpty) {
      final firstStation = _orderedStations.first.station;
      _currentBusPosition = LatLng(
        firstStation.latitude,
        firstStation.longitude,
      );
    }

    // Kết nối WebSocket và join room
    await _connectAndJoinTrip(trip.id);

    notifyListeners();
  }

  /// Xử lý dữ liệu tuyến: decode polyline, sắp xếp trạm theo chiều.
  void _processRouteData(TripModel trip) {
    final route = trip.route;
    if (route == null) return;

    // Sắp xếp trạm theo chiều
    final stations = List<TripRouteStationModel>.from(route.stations);
    if (trip.isDropOff) {
      stations.sort((a, b) => b.orderIndex.compareTo(a.orderIndex));
    } else {
      stations.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }
    _orderedStations = stations;

    // Decode polyline
    if (route.encodedPolyline != null &&
        route.encodedPolyline!.isNotEmpty) {
      _polylinePoints = PolylineDecoder.decode(route.encodedPolyline);
      // Đảo ngược polyline nếu chiều về
      if (trip.isDropOff) {
        _polylinePoints = _polylinePoints.reversed.toList();
      }
    } else {
      // Fallback: nối tọa độ các trạm
      _polylinePoints = _orderedStations
          .map((s) => LatLng(s.station.latitude, s.station.longitude))
          .toList();
    }
  }

  /// Kết nối Socket.IO và join room tracking.
  Future<void> _connectAndJoinTrip(String tripId) async {
    try {
      await _socketService.connect();
      _socketService.joinTrip(tripId);
      _socketService.onLocationUpdated(_onLocationUpdated);
      _socketService.onSimulationCompleted(_onSimulationCompleted);
    } catch (e) {
      // Không throw — tracking vẫn hoạt động qua polling nếu WS lỗi
      debugPrint('WebSocket connection error: $e');
    }
  }

  /// Callback khi nhận tọa độ mới từ WebSocket.
  void _onLocationUpdated(double lat, double lng) {
    _currentBusPosition = LatLng(lat, lng);
    notifyListeners();
  }

  /// Callback khi giả lập hoàn thành.
  void _onSimulationCompleted() {
    // Reload để cập nhật trạng thái chuyến đi
    loadActiveTrips();
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
