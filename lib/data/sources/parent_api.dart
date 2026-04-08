import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/login_response.dart';
import '../models/child_model.dart';

/// Data source giao tiếp trực tiếp với backend cho luồng Parent.
class ParentApi {
  final DioClient _dioClient;

  ParentApi(this._dioClient);

  /// Gọi API GET /users/me.
  /// Trả về [UserModel] nếu thành công.
  Future<UserModel> getProfile() async {
    try {
      final response = await _dioClient.dio.get('/users/me');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        return UserModel.fromJson(result);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Lấy thông tin cá nhân thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy profile: $e');
    }
  }

  /// Gọi API GET /users/my-children.
  /// Trả về danh sách [ChildModel] nếu thành công.
  Future<List<ChildModel>> getMyChildren() async {
    try {
      final response = await _dioClient.dio.get('/users/my-children');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as List<dynamic>? ?? [];
        return result
            .map((e) => ChildModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Lấy danh sách học sinh thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy danh sách HS: $e');
    }
  }

  /// Gọi API POST /users/link-student.
  /// Liên kết phụ huynh với học sinh qua số điện thoại.
  Future<void> linkStudent(String phone) async {
    try {
      final response = await _dioClient.dio.post(
        '/users/link-student',
        data: {'phone': phone},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Liên kết học sinh thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi liên kết HS: $e');
    }
  }
}
