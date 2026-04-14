import '../models/trip_model.dart';

abstract class DriverTripRepository {
  /// Lấy danh sách chuyến đi được gán cho tài xế theo ngày.
  Future<List<TripModel>> getMyDriverTrips({String? date});

  /// Bắt đầu chuyến đi (PENDING → IN_PROGRESS).
  Future<TripModel> startTrip(String tripId);

  /// Cập nhật trạm hiện tại của chuyến đi.
  Future<TripModel> updateStation(String tripId, int nextStationIndex);

  /// Hoàn thành chuyến đi (IN_PROGRESS → COMPLETED).
  Future<TripModel> completeTrip(String tripId);

  /// Lấy danh sách học sinh cần đón/trả tại một trạm.
  Future<Map<String, dynamic>> getStudentsAtStation(
    String tripId,
    String stationId,
  );

  /// Lấy tất cả học sinh + trạng thái điểm danh trong chuyến đi.
  Future<Map<String, dynamic>> getTripAttendances(String tripId);

  /// Điểm danh học sinh (BOARDED / ABSENT / ALIGHTED).
  Future<Map<String, dynamic>> markAttendance(
    String tripId,
    String studentId,
    String status,
  );

  /// Quét QR vé → verify + tự động điểm danh BOARDED.
  Future<Map<String, dynamic>> verifyTicket(
    String tripId,
    String ticketId,
  );

  /// Lấy tổng hợp số HS cần đón/trả tại mỗi trạm.
  Future<Map<String, dynamic>> getStationSummary(String tripId);

  /// Giả lập chuyến đi — backend phát toạ độ qua WebSocket.
  Future<void> simulateTrip(String tripId);
}
