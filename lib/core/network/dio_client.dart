import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// HTTP Client wrapper sử dụng Dio.
/// Tự động gắn Bearer Token vào header và xử lý lỗi global.
class DioClient {
  late final Dio _dio;

  /// Token lưu trong bộ nhớ để tránh race condition với SharedPreferences.
  String? _accessToken;

  /// Constructor private — dùng [create] để khởi tạo.
  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  /// Async factory: tạo instance và **đợi** load token từ storage xong
  /// trước khi trả về, tránh race condition.
  static Future<DioClient> create() async {
    final client = DioClient._();
    final prefs = await SharedPreferences.getInstance();
    client._accessToken = prefs.getString('access_token');
    return client;
  }

  Dio get dio => _dio;

  /// Gán token trực tiếp vào bộ nhớ (gọi sau khi login/register thành công).
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Xóa token khỏi bộ nhớ.
  void clearAccessToken() {
    _accessToken = null;
  }

  /// Interceptor tự động gắn Bearer Token vào mọi request.
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ưu tiên token trong bộ nhớ, fallback SharedPreferences
        String? token = _accessToken;
        if (token == null || token.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          token = prefs.getString('access_token');
          _accessToken = token;
        }
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    );
  }

  /// Interceptor xử lý lỗi global (401 → clear token).
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          _accessToken = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('access_token');
          // TODO: Navigate to login screen
        }
        handler.next(error);
      },
    );
  }
}
