import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/repositories/driver_trip_repository.dart';

class DriverScheduleController extends ChangeNotifier {
  final DriverTripRepository _driverTripRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<TripModel> _todayTrips = [];
  List<TripModel> get todayTrips => _todayTrips;

  String? _error;
  String? get error => _error;

  // Ngày đang được chọn trên giao diện
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  DriverScheduleController({required DriverTripRepository driverTripRepository})
      : _driverTripRepository = driverTripRepository;

  /// Chọn ngày → tự động load lại trips.
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    fetchTrips();
  }

  /// Format ngày sang chuỗi YYYY-MM-DD cho API.
  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  /// Load lịch trình tài xế từ API theo ngày đã chọn.
  Future<void> fetchTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trips = await _driverTripRepository.getMyDriverTrips(
        date: _formattedDate,
      );

      // Sort theo giờ bắt đầu sớm nhất lên đầu
      trips.sort((a, b) {
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      });

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
