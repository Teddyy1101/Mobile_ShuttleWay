import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/trip_model.dart';

/// Data source giao tiếp trực tiếp với backend cho luồng Trip/Tracking.
class TripApi {
  final DioClient _dioClient;

  TripApi(this._dioClient);

  /// Gọi API `GET /trips/my-active-trips`.
  /// Trả về danh sách [TripModel] đang IN_PROGRESS thuộc tuyến có vé ACTIVE.
  Future<List<TripModel>> getMyActiveTrips() async {
    try {
      final response = await _dioClient.dio.get('/trips/my-active-trips');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as List<dynamic>? ?? [];
        return result
            .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Lấy danh sách chuyến đi thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy chuyến đi: $e');
    }
  }

  /// Gọi API `GET /trips/:id/tracking`.
  /// Trả về chi tiết tracking chuyến đi.
  Future<TripModel> getTripTracking(String tripId) async {
    try {
      final response = await _dioClient.dio.get('/trips/$tripId/tracking');

      if (response.statusCode == 200) {
        return TripModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Lấy thông tin tracking thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy tracking: $e');
    }
  }

  /// Gọi API `GET /trips/my-schedule`.
  /// Trả về lịch trình chuyến đi theo ngày, hỗ trợ lọc theo [studentId].
  Future<List<TripModel>> getMySchedule(
    String date, {
    String? studentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'date': date};
      if (studentId != null) {
        queryParams['studentId'] = studentId;
      }

      final response = await _dioClient.dio.get(
        '/trips/my-schedule',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as List<dynamic>? ?? [];
        return result
            .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Lấy lịch trình thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy lịch trình: $e');
    }
  }
}
