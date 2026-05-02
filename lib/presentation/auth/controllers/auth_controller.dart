import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/login_request.dart';
import '../../../data/models/login_response.dart';
import '../../../data/models/register_request.dart';
import '../../../data/models/register_response.dart';
import '../../../data/models/social_login_request.dart';
import '../../../data/models/social_login_response.dart';
import '../../../data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;
  final DioClient _dioClient;

  AuthController(this._authRepository, this._dioClient);

  //State
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;
  String? _tempIdToken;

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

  /// Gọi backend để đăng nhập/đăng ký bằng mạng xã hội.
  Future<SocialLoginResponse?> socialLogin(String idToken, {String? role, String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = SocialLoginRequest(
        idToken: idToken,
        role: role,
        phone: phone,
      );
      final response = await _authRepository.socialLogin(request);

      if (!response.requiresAdditionalInfo && response.loginData != null) {
        // Lưu token vào bộ nhớ + local storage
        _dioClient.setAccessToken(response.loginData!.accessToken);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', response.loginData!.accessToken);

        _user = response.loginData!.user;
      }
      
      _isLoading = false;
      notifyListeners();
      return response;
    } on DioException catch (e) {
      _isLoading = false;
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
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
      return null;
    }
  }

  /// Đăng nhập bằng Google.
  Future<SocialLoginResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // Người dùng hủy đăng nhập

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        _tempIdToken = idToken;
        return await socialLogin(idToken);
      }
    } catch (e) {
      _errorMessage = 'Đăng nhập Google thất bại: $e';
      notifyListeners();
    }
    return null;
  }

  /// Đăng nhập bằng Facebook.
  Future<SocialLoginResponse?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final idToken = await userCredential.user?.getIdToken();

        if (idToken != null) {
          _tempIdToken = idToken;
          return await socialLogin(idToken);
        }
      } else if (result.status == LoginStatus.cancelled) {
        return null; // Người dùng hủy
      } else {
        _errorMessage = 'Đăng nhập Facebook thất bại: ${result.message}';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Đăng nhập Facebook thất bại: $e';
      notifyListeners();
    }
    return null;
  }

  /// Hoàn tất đăng ký mxh khi user mới
  Future<bool> completeSocialLogin(String role, String phone) async {
    if (_tempIdToken == null) return false;
    final response = await socialLogin(_tempIdToken!, role: role, phone: phone);
    if (response != null && !response.requiresAdditionalInfo) {
      _tempIdToken = null;
      return true;
    }
    return false;
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
