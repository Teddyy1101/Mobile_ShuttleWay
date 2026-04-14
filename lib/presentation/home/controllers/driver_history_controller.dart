import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/repositories/driver_trip_repository.dart';

class DriverHistoryController extends ChangeNotifier {
  final DriverTripRepository _driverTripRepository;

  DriverHistoryController(this._driverTripRepository);

  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  List<TripModel> _trips = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  List<TripModel> get trips => _trips;

  /// Các chuyến đã hoàn thành.
  List<TripModel> get completedTrips =>
      _trips.where((t) => t.status.toUpperCase() == 'COMPLETED').toList();

  /// Các chuyến chưa hoàn thành (PENDING, IN_PROGRESS, CANCELLED).
  List<TripModel> get otherTrips =>
      _trips.where((t) => t.status.toUpperCase() != 'COMPLETED').toList();

  /// Tải danh sách chuyến theo ngày.
  Future<void> loadTrips({DateTime? date}) async {
    if (date != null) _selectedDate = date;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _trips = await _driverTripRepository.getMyDriverTrips(date: dateStr);

      // Sắp xếp: COMPLETED lên đầu, sau đó theo thời gian
      _trips.sort((a, b) {
        final aCompleted = a.status.toUpperCase() == 'COMPLETED' ? 0 : 1;
        final bCompleted = b.status.toUpperCase() == 'COMPLETED' ? 0 : 1;
        if (aCompleted != bCompleted) return aCompleted.compareTo(bCompleted);
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
      _errorMessage = 'Đã xảy ra lỗi khi tải lịch sử';
      notifyListeners();
    }
  }

  /// Chuyển sang ngày khác.
  void changeDate(DateTime newDate) {
    loadTrips(date: newDate);
  }

  String _parseDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'Phiên đăng nhập hết hạn';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Không thể kết nối đến server';
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
