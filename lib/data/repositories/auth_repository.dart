import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';

/// Interface (Abstract class) cho Auth Repository.
/// Tất cả các tầng trên (Controller/Bloc) chỉ gọi qua interface này
/// để tuân thủ Dependency Inversion Principle.
abstract class AuthRepository {
  /// Đăng nhập bằng email và mật khẩu.
  Future<LoginResponse> login(LoginRequest request);

  /// Đăng ký tài khoản mới.
  Future<RegisterResponse> register(RegisterRequest request);
}
