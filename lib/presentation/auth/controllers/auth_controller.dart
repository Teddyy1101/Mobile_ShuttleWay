import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/login_request.dart';
import '../../../data/models/login_response.dart';
import '../../../data/models/register_request.dart';
import '../../../data/models/register_response.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;
  final DioClient _dioClient;

  AuthController(this._authRepository, this._dioClient);

  //State
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  /// Lưu accessToken vào SharedPreferences nếu thành công.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _authRepository.login(request);

      // Lưu token vào bộ nhớ + local storage
      _dioClient.setAccessToken(response.accessToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response.accessToken);

      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.statusCode == 401) {
        _errorMessage = 'Email hoặc mật khẩu không đúng';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _errorMessage = 'Không thể kết nối đến server. Vui lòng thử lại';
      } else {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          final msg = data['message'];
          if (msg is List) {
            _errorMessage = msg.join(', ');
          } else {
            _errorMessage = msg?.toString() ?? 'Đã xảy ra lỗi';
          }
        } else {
          _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại';
        }
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
      return false;
    }
  }

  /// Đăng ký tài khoản mới.
  Future<bool> register(
    String fullName,
    String email,
    String phone,
    String password,
    String role,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      final response = await _authRepository.register(request);

      // Lưu token vào bộ nhớ + local storage
      _dioClient.setAccessToken(response.accessToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response.accessToken);

      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.statusCode == 409) {
        _errorMessage = 'Email đã được sử dụng';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _errorMessage = 'Không thể kết nối đến server. Vui lòng thử lại';
      } else {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          final msg = data['message'];
          if (msg is List) {
            _errorMessage = msg.join(', ');
          } else {
            _errorMessage = msg?.toString() ?? 'Đã xảy ra lỗi';
          }
        } else {
          _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại';
        }
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
      return false;
    }
  }

  /// Quên mật khẩu — gửi email chứa mật khẩu mới.
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dioClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      _isLoading = false;
      notifyListeners();

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return true;
      }
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        _errorMessage = data['message']?.toString() ?? 'Đã xảy ra lỗi';
      } else {
        _errorMessage = 'Không thể kết nối đến server. Vui lòng thử lại';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
      return false;
    }
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
