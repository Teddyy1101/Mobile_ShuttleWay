import '../models/trip_model.dart';

/// Repository trừu tượng cho luồng Trip / Tracking.
abstract class TripRepository {
  /// Lấy danh sách chuyến đi đang hoạt động (IN_PROGRESS).
  Future<List<TripModel>> getMyActiveTrips();

  /// Lấy chi tiết tracking chuyến đi.
  Future<TripModel> getTripTracking(String tripId);

  /// Lấy lịch trình chuyến đi theo ngày, hỗ trợ lọc theo [studentId].
  Future<List<TripModel>> getMySchedule(String date, {String? studentId});
}
