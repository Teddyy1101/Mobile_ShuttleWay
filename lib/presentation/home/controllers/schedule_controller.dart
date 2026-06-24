import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/repositories/trip_repository.dart';

/// Controller quản lý state cho màn hình Lịch trình.
/// Hỗ trợ chọn ngày, chọn học sinh (PARENT), load trips theo API mới.
class ScheduleController extends ChangeNotifier {
  final TripRepository _tripRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<TripModel> _todayTrips = [];
  List<TripModel> get todayTrips => _todayTrips;

  String? _error;
  String? get error => _error;

  // Ngày đang được chọn trên giao diện
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Học sinh đang được chọn (chỉ dùng cho PARENT)
  ChildModel? _selectedChild;
  ChildModel? get selectedChild => _selectedChild;

  // Chế độ phụ huynh — nếu true, bắt buộc phải có selectedChild mới gọi API
  bool _isParentMode = false;
  bool get isParentMode => _isParentMode;

  ScheduleController({required TripRepository tripRepository})
      : _tripRepository = tripRepository;

  /// Đặt chế độ phụ huynh (gọi từ screen khi biết user role).
  void setParentMode(bool value) {
    _isParentMode = value;
  }

  /// Chọn ngày → tự động load lại trips.
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    fetchTrips();
  }

  /// Chọn học sinh (PARENT) → load lại trips theo studentId.
  void selectChild(ChildModel? child) {
    _selectedChild = child;
    notifyListeners();
    fetchTrips();
  }

  /// Format ngày sang chuỗi YYYY-MM-DD cho API.
  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  /// Load lịch trình từ API theo ngày đã chọn.
  Future<void> fetchTrips() async {
    // Nếu là phụ huynh nhưng chưa chọn/liên kết học sinh → bỏ qua
    if (_isParentMode && _selectedChild == null) {
      _todayTrips = [];
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trips = await _tripRepository.getMySchedule(
        _formattedDate,
        studentId: _selectedChild?.id,
      );
      _todayTrips = trips;
    } catch (e) {
      _error = 'Không thể tải lịch trình: $e';
      _todayTrips = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
