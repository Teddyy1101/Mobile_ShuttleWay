import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/social_login_request.dart';
import '../models/social_login_response.dart';

/// Data source giao tiếp trực tiếp với backend cho luồng Auth.
class AuthApi {
  final DioClient _dioClient;

  AuthApi(this._dioClient);

  /// Gọi API POST /auth/login.
  /// Trả về [LoginResponse] nếu thành công.
  /// Ném [DioException] nếu lỗi mạng hoặc server.
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/login',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Đăng nhập thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi đăng nhập: $e');
    }
  }

  /// Gọi API POST /auth/register.
  /// Trả về [RegisterResponse] nếu thành công.
  /// Ném [DioException] nếu lỗi mạng hoặc server.
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/register',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RegisterResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Đăng ký thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi đăng ký: $e');
    }
  }

  /// Gọi API POST /auth/social-login.
  Future<SocialLoginResponse> socialLogin(SocialLoginRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/social-login',
        data: request.toJson(),
      );

      // 200: OK, 202: Accepted (Cần thêm info)
      if (response.statusCode == 200 || response.statusCode == 202) {
        return SocialLoginResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Đăng nhập social thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi đăng nhập social: $e');
    }
  }
}
