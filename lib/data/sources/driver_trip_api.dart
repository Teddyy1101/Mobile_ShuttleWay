import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/trip_model.dart';

class DriverTripApi {
  final DioClient _dioClient;

  DriverTripApi(this._dioClient);

  Future<List<TripModel>> getMyDriverTrips({String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date;
      }

      final response = await _dioClient.dio.get(
        '/trips/my-driver-trips',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as List<dynamic>? ?? [];
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
      throw Exception('Lỗi không xác định khi lấy chuyến đi tài xế: $e');
    }
  }

  /// Bắt đầu chuyến đi.
  Future<TripModel> startTrip(String tripId) async {
    try {
      final response = await _dioClient.dio.patch('/trips/$tripId/start');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // Backend trả về trip object trực tiếp hoặc trong `data`
        final tripData = data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data;
        return TripModel.fromJson(tripData);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Bắt đầu chuyến đi thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi bắt đầu chuyến đi: $e');
    }
  }

  /// Cập nhật trạm hiện tại.
  Future<TripModel> updateStation(
    String tripId,
    int nextStationIndex,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        '/trips/$tripId/station',
        data: {'nextStationIndex': nextStationIndex},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final tripData = data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data;
        return TripModel.fromJson(tripData);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Cập nhật trạm thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi cập nhật trạm: $e');
    }
  }

  /// Hoàn thành chuyến đi.
  Future<TripModel> completeTrip(String tripId) async {
    try {
      final response = await _dioClient.dio.patch('/trips/$tripId/complete');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final tripData = data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data;
        return TripModel.fromJson(tripData);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Hoàn thành chuyến đi thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi hoàn thành chuyến đi: $e');
    }
  }

  /// Lấy danh sách học sinh tại trạm.
  Future<Map<String, dynamic>> getStudentsAtStation(
    String tripId,
    String stationId,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        '/trips/$tripId/stations/$stationId/students',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>? ?? {};
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Lấy DS học sinh tại trạm thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy DS học sinh: $e');
    }
  }

  /// Lấy danh sách tất cả học sinh + trạng thái điểm danh trong chuyến đi.
  Future<Map<String, dynamic>> getTripAttendances(String tripId) async {
    try {
      final response = await _dioClient.dio.get(
        '/trips/$tripId/attendances',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>? ?? {};
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Lấy DS điểm danh thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy DS điểm danh: $e');
    }
  }
  /// Điểm danh học sinh (BOARDED / ABSENT / ALIGHTED).
  Future<Map<String, dynamic>> markAttendance(
    String tripId,
    String studentId,
    String status,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '/trips/$tripId/attendance',
        data: {'studentId': studentId, 'status': status},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Điểm danh thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi điểm danh: $e');
    }
  }

  /// Quét QR vé → verify + tự động điểm danh BOARDED.
  Future<Map<String, dynamic>> verifyTicket(
    String tripId,
    String ticketId,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '/trips/$tripId/verify-ticket',
        data: {'ticketId': ticketId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Xác minh vé thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi xác minh vé: $e');
    }
  }

  /// Lấy tổng hợp số HS cần đón/trả tại mỗi trạm.
  Future<Map<String, dynamic>> getStationSummary(String tripId) async {
    try {
      final response = await _dioClient.dio.get(
        '/trips/$tripId/station-summary',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>? ?? {};
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Lấy tổng hợp trạm thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy tổng hợp trạm: $e');
    }
  }

  /// Giả lập chuyến đi — backend phát tọa độ qua WebSocket.
  Future<void> simulateTrip(String tripId) async {
    try {
      final response = await _dioClient.dio.post('/trips/$tripId/simulate');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Giả lập chuyến đi thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi giả lập chuyến đi: $e');
    }
  }
}
