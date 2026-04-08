import 'login_response.dart';

/// Model cho response đăng ký từ backend.
/// Cấu trúc tương tự [LoginResponse] vì server trả về token ngay sau đăng ký.
class RegisterResponse {
  final String message;
  final String accessToken;
  final UserModel user;

  const RegisterResponse({
    required this.message,
    required this.accessToken,
    required this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final result = json['data'] as Map<String, dynamic>? ?? {};
    return RegisterResponse(
      message: json['message'] as String? ?? '',
      accessToken: result['accessToken'] as String? ?? '',
      user: UserModel.fromJson(
        result['user'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
