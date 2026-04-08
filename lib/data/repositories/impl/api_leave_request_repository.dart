import 'package:dio/dio.dart';
import '../leave_request_repository.dart';

class ApiLeaveRequestRepository implements LeaveRequestRepository {
  final Dio _dio;

  ApiLeaveRequestRepository(this._dio);

  @override
  Future<void> createLeaveRequest({
    required String studentId,
    required String parentId,
    required String fromDate,
    required String toDate,
    String? reason,
  }) async {
    try {
      final data = {
        'studentId': studentId,
        'parentId': parentId,
        'fromDate': fromDate,
        'toDate': toDate,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      };

      await _dio.post('/leave-requests', data: data);
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          throw Exception(data['message'].toString());
        }
      }
      throw Exception('Không thể gửi đơn xin nghỉ. Vui lòng thử lại sau.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }
}
