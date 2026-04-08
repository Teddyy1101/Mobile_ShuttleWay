import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/ticket_model.dart';

/// Data source giao tiếp trực tiếp với backend cho luồng Ticket.
class TicketApi {
  final DioClient _dioClient;

  TicketApi(this._dioClient);

  /// Gọi API POST /tickets.
  /// Mua vé xe buýt. Trả về [TicketModel] nếu thành công.
  /// [selectedStationId] — ID trạm nhà mà học sinh chọn.
  Future<TicketModel> buyTicket({
    required String routeId,
    required String ticketType,
    required String selectedStationId,
    String? studentId,
  }) async {
    try {
      final body = <String, dynamic>{
        'routeId': routeId,
        'ticketType': ticketType,
        'selectedStationId': selectedStationId,
      };
      if (studentId != null) body['studentId'] = studentId;

      final response = await _dioClient.dio.post('/tickets', data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        return TicketModel.fromJson(result);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Mua vé thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi mua vé: $e');
    }
  }

  Future<TicketListResponse> getMyTickets({
    int page = 1,
    int limit = 20,
    String? ticketType,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (ticketType != null) queryParams['ticketType'] = ticketType;
      if (status != null) queryParams['status'] = status;

      final response = await _dioClient.dio.get(
        '/tickets/my-tickets',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        final itemsList = result['data'] as List<dynamic>? ?? [];
        final meta = result['meta'] as Map<String, dynamic>? ?? {};

        return TicketListResponse(
          items: itemsList
              .map((e) =>
                  TicketModel.fromJson(e as Map<String, dynamic>))
              .toList(),
          total: meta['total'] as int? ?? 0,
          page: meta['page'] as int? ?? 1,
          limit: meta['limit'] as int? ?? 20,
          totalPages: meta['totalPages'] as int? ?? 0,
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Lấy danh sách vé thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy danh sách vé: $e');
    }
  }
}
