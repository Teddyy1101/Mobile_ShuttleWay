import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/repositories/ticket_repository.dart';

/// Controller quản lý state cho luồng đặt vé xe buýt.
/// Sử dụng ChangeNotifier + ListenableBuilder pattern.
///
/// Nghiệp vụ: Học sinh chỉ chọn **trạm đón** (trạm nhà).
/// Điểm trả mặc định là trường học (trạm cuối trên tuyến).
class TicketController extends ChangeNotifier {
  final TicketRepository _ticketRepository;

  TicketController(this._ticketRepository);

  // ─── State ────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  List<RouteModel> _routes = [];
  RouteModel? _selectedRoute;
  String _selectedTicketType = 'SINGLE_TRIP';
  ChildModel? _selectedChild;
  bool _isBuying = false;
  DateTime _selectedDate = DateTime.now();
  RouteStationModel? _selectedStation;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RouteModel> get routes => _routes;
  RouteModel? get selectedRoute => _selectedRoute;
  String get selectedTicketType => _selectedTicketType;
  ChildModel? get selectedChild => _selectedChild;
  bool get isBuying => _isBuying;
  DateTime get selectedDate => _selectedDate;

  /// Trạm đón (trạm nhà) mà học sinh đã chọn.
  RouteStationModel? get selectedStation => _selectedStation;

  /// Giá vé hiện tại dựa trên loại vé và tuyến đường đã chọn.
  double get currentPrice {
    if (_selectedRoute == null) return 0;
    return _selectedTicketType == 'MONTHLY'
        ? _selectedRoute!.monthlyPrice
        : _selectedRoute!.singlePrice;
  }

  /// Tải danh sách tuyến đường khả dụng.
  Future<void> loadRoutes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _routes = await _ticketRepository.getRoutes();
      // Tự động chọn tuyến đầu tiên nếu có
      if (_routes.isNotEmpty && _selectedRoute == null) {
        _selectedRoute = _routes.first;
        _autoSelectStation(_selectedRoute!);
      }
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định khi tải tuyến đường';
      notifyListeners();
    }
  }

  /// Chọn tuyến đường. Tự động gán trạm đón = trạm đầu tiên.
  void selectRoute(RouteModel route) {
    _selectedRoute = route;
    _autoSelectStation(route);
    notifyListeners();
  }

  /// Tự động gán trạm đón = trạm đầu tiên trên tuyến.
  void _autoSelectStation(RouteModel route) {
    if (route.stations.isNotEmpty) {
      _selectedStation = route.stations.first;
    } else {
      _selectedStation = null;
    }
  }

  /// Chọn trạm đón (trạm nhà).
  /// Không cho phép chọn trạm cuối cùng (trạm trường).
  void selectStation(RouteStationModel station) {
    _selectedStation = station;
    notifyListeners();
  }

  /// Danh sách trạm hợp lệ để chọn (tất cả trừ trạm cuối — trạm trường).
  List<RouteStationModel> get selectableStations {
    if (_selectedRoute == null || _selectedRoute!.stations.isEmpty) return [];
    // Loại bỏ trạm cuối cùng (trạm trường)
    return _selectedRoute!.stations
        .sublist(0, _selectedRoute!.stations.length - 1);
  }

  /// Chọn loại vé: SINGLE_TRIP hoặc MONTHLY.
  void selectTicketType(String type) {
    _selectedTicketType = type;
    notifyListeners();
  }

  /// Chọn học sinh (chỉ dành cho PARENT).
  void selectChild(ChildModel child) {
    _selectedChild = child;
    notifyListeners();
  }

  /// Chọn ngày khởi hành.
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Xác nhận đặt vé.
  /// Trả về [TicketModel] nếu thành công, null nếu thất bại.
  Future<TicketModel?> buyTicket({String? studentId}) async {
    if (_selectedRoute == null) {
      _errorMessage = 'Vui lòng chọn tuyến đường';
      notifyListeners();
      return null;
    }

    if (_selectedStation == null) {
      _errorMessage = 'Vui lòng chọn trạm đón';
      notifyListeners();
      return null;
    }

    _isBuying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ticket = await _ticketRepository.buyTicket(
        routeId: _selectedRoute!.id,
        ticketType: _selectedTicketType,
        selectedStationId: _selectedStation!.station.id,
        studentId: studentId ?? _selectedChild?.id,
      );
      _isBuying = false;
      notifyListeners();
      return ticket;
    } on DioException catch (e) {
      _isBuying = false;
      _handleDioError(e);
      notifyListeners();
      return null;
    } catch (e) {
      _isBuying = false;
      _errorMessage = 'Lỗi không xác định khi đặt vé';
      notifyListeners();
      return null;
    }
  }

  /// Reset trạng thái cho lần đặt vé mới.
  void reset() {
    _selectedRoute = _routes.isNotEmpty ? _routes.first : null;
    _selectedTicketType = 'SINGLE_TRIP';
    _selectedChild = null;
    _errorMessage = null;
    if (_selectedRoute != null) {
      _autoSelectStation(_selectedRoute!);
    } else {
      _selectedStation = null;
    }
    notifyListeners();
  }

  /// Xoá thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
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
