/// Model chứa thông tin user trả về sau khi đăng nhập.
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final String? phone;
  final String? googleId;
  final String? facebookId;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.googleId,
    this.facebookId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      googleId: json['googleId'] as String?,
      facebookId: json['facebookId'] as String?,
    );
  }

  /// Tạo bản sao với các field được thay đổi.
  UserModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? googleId,
    String? facebookId,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      googleId: googleId ?? this.googleId,
      facebookId: facebookId ?? this.facebookId,
    );
  }
}

/// Model cho response đăng nhập từ backend.
class LoginResponse {
  final String message;
  final String accessToken;
  final UserModel user;

  const LoginResponse({
    required this.message,
    required this.accessToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final result = json['data'] as Map<String, dynamic>? ?? {};
    return LoginResponse(
      message: json['message'] as String? ?? '',
      accessToken: result['accessToken'] as String? ?? '',
      user: UserModel.fromJson(
        result['user'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
