/// Model cho request đăng ký tài khoản mới.
class RegisterRequest {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String role;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    };
  }
}

