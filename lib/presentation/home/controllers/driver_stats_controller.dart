import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/repositories/driver_trip_repository.dart';

class DailyStats {
  final DateTime date;
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final int cancelled;
  final int studentCount;

  const DailyStats({
    required this.date,
    this.total = 0,
    this.completed = 0,
    this.inProgress = 0,
    this.pending = 0,
    this.cancelled = 0,
    this.studentCount = 0,
  });
}

/// Controller xử lý logic thống kê hoạt động của tài xế.
/// Tính toán client-side từ API `GET /trips/my-driver-trips`.
class DriverStatsController extends ChangeNotifier {
  final DriverTripRepository _repository;

  DriverStatsController(this._repository);

  bool _isLoading = false;
  String? _error;

  /// Thống kê hôm nay.
  DailyStats _todayStats = DailyStats(date: DateTime.now());

  /// Thống kê 7 ngày trong tuần hiện tại (Thứ 2 → Chủ nhật).
  List<DailyStats> _weeklyData = [];

  /// Tổng chuyến đã hoàn thành trong tuần.
  int _weeklyCompleted = 0;

  /// Tổng chuyến trong tuần.
  int _weeklyTotal = 0;

  /// Tổng số học sinh đã phục vụ trong tuần.
  int _weeklyStudents = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  DailyStats get todayStats => _todayStats;
  List<DailyStats> get weeklyData => _weeklyData;
  int get weeklyCompleted => _weeklyCompleted;
  int get weeklyTotal => _weeklyTotal;
  int get weeklyStudents => _weeklyStudents;

  /// Tỷ lệ hoàn thành trong tuần (0.0 → 1.0).
  double get weeklyCompletionRate {
    if (_weeklyTotal == 0) return 0;
    return _weeklyCompleted / _weeklyTotal;
  }

  /// Chuyến hoàn thành trong ngày nhiều nhất (dùng để scale biểu đồ).
  int get maxDailyTrips {
    if (_weeklyData.isEmpty) return 1;
    final maxVal = _weeklyData
        .map((d) => d.total)
        .reduce((a, b) => a > b ? a : b);
    return maxVal > 0 ? maxVal : 1;
  }

  /// Load toàn bộ dữ liệu thống kê (hôm nay + tuần).
  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd');

      // Tính ngày đầu tuần (Thứ 2)
      final monday = now.subtract(Duration(days: now.weekday - 1));

      // Gọi API cho 7 ngày trong tuần
      final List<DailyStats> weekStats = [];
      int totalWeekTrips = 0;
      int totalWeekCompleted = 0;
      int totalWeekStudents = 0;

      for (int i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        final dateStr = formatter.format(day);

        List<TripModel> trips = [];
        try {
          trips = await _repository.getMyDriverTrips(date: dateStr);
        } catch (_) {
          // Nếu lỗi 1 ngày → bỏ qua, không crash toàn bộ
        }

        final stats = _computeDailyStats(day, trips);
        weekStats.add(stats);

        totalWeekTrips += stats.total;
        totalWeekCompleted += stats.completed;
        totalWeekStudents += stats.studentCount;

        // Nếu là ngày hôm nay → lưu riêng
        if (day.year == now.year &&
            day.month == now.month &&
            day.day == now.day) {
          _todayStats = stats;
        }
      }

      _weeklyData = weekStats;
      _weeklyTotal = totalWeekTrips;
      _weeklyCompleted = totalWeekCompleted;
      _weeklyStudents = totalWeekStudents;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Không thể tải dữ liệu thống kê';
      notifyListeners();
    }
  }

  /// Tính toán thống kê từ danh sách chuyến đi trong ngày.
  DailyStats _computeDailyStats(DateTime date, List<TripModel> trips) {
    int completed = 0;
    int inProgress = 0;
    int pending = 0;
    int cancelled = 0;
    int students = 0;

    for (final trip in trips) {
      switch (trip.status.toUpperCase()) {
        case 'COMPLETED':
          completed++;
          break;
        case 'IN_PROGRESS':
          inProgress++;
          break;
        case 'PENDING':
          pending++;
          break;
        case 'CANCELLED':
          cancelled++;
          break;
      }
      students += trip.attendanceCount;
    }

    return DailyStats(
      date: date,
      total: trips.length,
      completed: completed,
      inProgress: inProgress,
      pending: pending,
      cancelled: cancelled,
      studentCount: students,
    );
  }

}
