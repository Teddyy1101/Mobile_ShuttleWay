import '../ticket_repository.dart';
import '../../sources/route_api.dart';
import '../../sources/ticket_api.dart';
import '../../models/route_model.dart';
import '../../models/ticket_model.dart';

/// Implement [TicketRepository] sử dụng RouteApi và TicketApi.
class ApiTicketRepository implements TicketRepository {
  final RouteApi _routeApi;
  final TicketApi _ticketApi;

  ApiTicketRepository(this._routeApi, this._ticketApi);

  @override
  Future<List<RouteModel>> getRoutes() async {
    return _routeApi.getRoutes(isActive: true);
  }

  @override
  Future<TicketModel> buyTicket({
    required String routeId,
    required String ticketType,
    required String selectedStationId,
    String? studentId,
  }) async {
    return _ticketApi.buyTicket(
      routeId: routeId,
      ticketType: ticketType,
      selectedStationId: selectedStationId,
      studentId: studentId,
    );
  }
}
