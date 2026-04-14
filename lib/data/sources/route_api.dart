import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/route_model.dart';

/// Data source giao tiếp trực tiếp với backend cho luồng Route.
class RouteApi {
  final DioClient _dioClient;

  RouteApi(this._dioClient);

  Future<List<RouteModel>> getRoutes({
    String? shiftType,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (shiftType != null) queryParams['shiftType'] = shiftType;
      if (isActive != null) queryParams['isActive'] = isActive;

      final response = await _dioClient.dio.get(
        '/routes',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        final itemsList = result['data'] as List<dynamic>? ?? [];

        return itemsList
            .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Lấy danh sách tuyến đường thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy danh sách tuyến đường: $e');
    }
  }
}
