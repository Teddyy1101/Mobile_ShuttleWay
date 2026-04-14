import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/login_response.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/repositories/driver_trip_repository.dart';

class DriverHomeController extends ChangeNotifier {
  final DriverTripRepository _driverTripRepository;

  DriverHomeController(this._driverTripRepository);

  /// Repository truy cập từ bên ngoài (dùng cho DriverStatsController).
  DriverTripRepository get driverTripRepository => _driverTripRepository;

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _profile;
  List<TripModel> _todayTrips = [];
  TripModel? _pendingTrip;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get profile => _profile;
  List<TripModel> get todayTrips => _todayTrips;
  TripModel? get pendingTrip => _pendingTrip;

  /// Chuyến đi tiếp theo (PENDING) — hiển thị ở card nổi bật.
  TripModel? get nextTrip {
    final pending = _todayTrips
        .where((t) => t.status.toUpperCase() == 'PENDING')
        .toList();
    return pending.isNotEmpty ? pending.first : null;
  }

  /// Chuyến đi đang chạy (IN_PROGRESS).
  TripModel? get activeTrip {
    final active = _todayTrips
        .where((t) => t.status.toUpperCase() == 'IN_PROGRESS')
        .toList();
    return active.isNotEmpty ? active.first : null;
  }

  /// Các chuyến còn lại (trừ chuyến tiếp theo đang hiển thị nổi bật).
  List<TripModel> get remainingTrips {
    final next = nextTrip;
    if (next == null) return _todayTrips;
    return _todayTrips.where((t) => t.id != next.id).toList();
  }

  /// Tài xế có đang chạy xe không.
  bool get isOnTrip => activeTrip != null;

  /// Có chuyến đang preview trên bản đồ hoặc đang active.
  bool get hasMapTrip => _pendingTrip != null || activeTrip != null;

  /// Chuyến hiển thị trên map — ưu tiên activeTrip, sau đó pendingTrip.
  TripModel? get mapTrip => activeTrip ?? _pendingTrip;

  /// Gán profile từ thông tin đăng nhập (tránh gọi lại API /users/me).
  void setProfileFromLogin(UserModel user) {
    _profile = user;
    notifyListeners();
  }

  /// Lời chào theo giờ trong ngày.
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng,';
    if (hour < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }

  /// Load danh sách chuyến đi hôm nay.
  Future<void> loadTodayTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _todayTrips = await _driverTripRepository.getMyDriverTrips(date: today);

      // Sort theo giờ bắt đầu sớm nhất lên đầu
      _todayTrips.sort((a, b) {
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      });

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

  /// Lưu chuyến vào pending (chưa gọi API) — để hiển thị preview trên map.
  void setPendingTrip(TripModel trip) {
    _pendingTrip = trip;
    notifyListeners();
  }

  /// Xoá pending trip sau khi startTrip thành công.
  void clearPendingTrip() {
    _pendingTrip = null;
    notifyListeners();
  }

  /// Trả về true nếu thành công (để UI chuyển tab).
  Future<bool> startTrip(String tripId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _driverTripRepository.startTrip(tripId);
      // Reload danh sách sau khi start
      await loadTodayTrips();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _parseDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi khi bắt đầu chuyến đi';
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật trạm hiện tại (gọi API updateStation).
  Future<bool> updateStation(String tripId, int nextStationIndex) async {
    try {
      await _driverTripRepository.updateStation(tripId, nextStationIndex);
      await loadTodayTrips();
      return true;
    } on DioException catch (e) {
      _errorMessage = _parseDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi khi cập nhật trạm';
      notifyListeners();
      return false;
    }
  }

  /// Giả lập chuyến đi — backend phát tọa độ qua WebSocket.
  Future<void> simulateTrip(String tripId) async {
    await _driverTripRepository.simulateTrip(tripId);
  }

  /// Hoàn thành chuyến đi (IN_PROGRESS → COMPLETED).
  Future<bool> completeTrip(String tripId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _driverTripRepository.completeTrip(tripId);
      await loadTodayTrips();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _parseDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi khi hoàn thành chuyến đi';
      notifyListeners();
      return false;
    }
  }

  /// Lấy danh sách học sinh tại một trạm cụ thể.
  Future<Map<String, dynamic>> getStudentsAtStation(
    String tripId,
    String stationId,
  ) async {
    try {
      return await _driverTripRepository.getStudentsAtStation(
        tripId,
        stationId,
      );
    } catch (e) {
      return {};
    }
  }

  /// Lấy tổng hợp số HS cần đón/trả tại mỗi trạm.
  Future<Map<String, dynamic>> getStationSummary(String tripId) async {
    try {
      return await _driverTripRepository.getStationSummary(tripId);
    } catch (e) {
      return {};
    }
  }

  /// Lấy toàn bộ danh sách điểm danh của chuyến đi.
  Future<List<Map<String, dynamic>>> getTripAttendances(String tripId) async {
    try {
      final data = await _driverTripRepository.getTripAttendances(tripId);
      final attendances = data['attendances'] as List<dynamic>? ?? [];
      return attendances
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Điểm danh học sinh (BOARDED / ABSENT / ALIGHTED).
  Future<bool> markAttendance(
    String tripId,
    String studentId,
    String status,
  ) async {
    try {
      await _driverTripRepository.markAttendance(tripId, studentId, status);
      return true;
    } on DioException catch (e) {
      _errorMessage = _parseDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi khi điểm danh';
      notifyListeners();
      return false;
    }
  }

  /// Quét QR vé → verify + tự động điểm danh BOARDED.
  Future<Map<String, dynamic>?> verifyTicket(
    String tripId,
    String ticketId,
  ) async {
    try {
      final result = await _driverTripRepository.verifyTicket(
        tripId,
        ticketId,
      );
      return result;
    } on DioException catch (e) {
      _errorMessage = _parseDioError(e);
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi khi xác minh vé';
      notifyListeners();
      return null;
    }
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Parse lỗi DioException thành chuỗi thân thiện.
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

