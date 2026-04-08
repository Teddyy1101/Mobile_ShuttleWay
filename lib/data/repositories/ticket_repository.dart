import '../models/route_model.dart';
import '../models/ticket_model.dart';

/// Interface (Abstract class) cho Ticket Repository.
/// Tất cả các tầng trên (Controller/Bloc) chỉ gọi qua interface này
/// để tuân thủ Dependency Inversion Principle.
abstract class TicketRepository {
  /// Lấy danh sách tuyến đường khả dụng.
  Future<List<RouteModel>> getRoutes();

  /// Mua vé xe buýt.
  /// [routeId] — ID tuyến đường.
  /// [ticketType] — Loại vé: MONTHLY hoặc SINGLE_TRIP.
  /// [selectedStationId] — ID trạm nhà mà học sinh chọn.
  /// [studentId] — ID học sinh (bắt buộc nếu role PARENT).
  Future<TicketModel> buyTicket({
    required String routeId,
    required String ticketType,
    required String selectedStationId,
    String? studentId,
  });
}
