import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/login_response.dart';
import '../models/child_model.dart';

/// Data source giao tiếp trực tiếp với backend cho luồng User chung.
/// Gom các API dùng chung cho cả PARENT và STUDENT.
class UserApi {
  final DioClient _dioClient;

  UserApi(this._dioClient);

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
        message:
            'Lấy thông tin cá nhân thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy profile: $e');
    }
  }

  /// Gọi API GET /users/my-children.
  /// Trả về danh sách [ChildModel] (dành cho PARENT).
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
        message:
            'Lấy danh sách học sinh thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy danh sách HS: $e');
    }
  }

  /// Gọi API GET /users/my-parents.
  /// Trả về danh sách [ChildModel] (dành cho STUDENT).
  /// Dùng chung ChildModel vì cấu trúc tương tự (id, fullName, email, phone, avatarUrl).
  Future<List<ChildModel>> getMyParents() async {
    try {
      final response = await _dioClient.dio.get('/users/my-parents');

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
        message:
            'Lấy danh sách phụ huynh thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy danh sách PH: $e');
    }
  }

  /// Gọi API PATCH /users/me (multipart/form-data).
  /// Cập nhật thông tin cá nhân: tên, SĐT, ảnh đại diện.
  /// Trả về [UserModel] đã cập nhật.
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarFilePath,
  }) async {
    try {
      final Map<String, dynamic> formMap = {};
      if (fullName != null) formMap['fullName'] = fullName;
      if (phone != null) formMap['phone'] = phone;
      if (avatarFilePath != null) {
        formMap['avatar'] = await MultipartFile.fromFile(avatarFilePath);
      }

      final formData = FormData.fromMap(formMap);

      final response = await _dioClient.dio.patch(
        '/users/me',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        return UserModel.fromJson(result);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Cập nhật thông tin thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi cập nhật thông tin: $e');
    }
  }

  /// Gọi API POST /users/link-student.
  /// Phụ huynh liên kết với học sinh qua số điện thoại.
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
        message:
            'Liên kết học sinh thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi liên kết học sinh: $e');
    }
  }

  /// Gọi API POST /users/link-parent.
  /// Học sinh liên kết với phụ huynh qua số điện thoại.
  Future<void> linkParent(String phone) async {
    try {
      final response = await _dioClient.dio.post(
        '/users/link-parent',
        data: {'phone': phone},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Liên kết phụ huynh thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi liên kết phụ huynh: $e');
    }
  }

  /// Gọi API DELETE /users/unlink-student/:studentId.
  /// Phụ huynh hủy liên kết với học sinh.
  Future<void> unlinkStudent(String studentId) async {
    try {
      final response = await _dioClient.dio.delete(
        '/users/unlink-student/$studentId',
      );

      if (response.statusCode == 200) {
        return;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Hủy liên kết học sinh thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi hủy liên kết học sinh: $e');
    }
  }

  /// Gọi API DELETE /users/unlink-parent/:parentId.
  /// Học sinh hủy liên kết với phụ huynh.
  Future<void> unlinkParent(String parentId) async {
    try {
      final response = await _dioClient.dio.delete(
        '/users/unlink-parent/$parentId',
      );

      if (response.statusCode == 200) {
        return;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Hủy liên kết phụ huynh thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi hủy liên kết phụ huynh: $e');
    }
  }

  /// Gọi API POST /auth/change-password.
  /// Đổi mật khẩu cho user đang đăng nhập.
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dioClient.dio.patch(
        '/auth/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Đổi mật khẩu thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi đổi mật khẩu: $e');
    }
  }

  /// Gọi API POST /users/me/link-social.
  /// Liên kết tài khoản Google hoặc Facebook.
  Future<void> linkSocial(String idToken) async {
    try {
      final response = await _dioClient.dio.post(
        '/users/me/link-social',
        data: {'idToken': idToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Liên kết tài khoản thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi liên kết tài khoản: $e');
    }
  }
}
