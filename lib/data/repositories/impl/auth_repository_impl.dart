import '../auth_repository.dart';
import '../../models/login_request.dart';
import '../../models/login_response.dart';
import '../../models/register_request.dart';
import '../../models/register_response.dart';
import '../../sources/auth_api.dart';
import '../../models/social_login_request.dart';
import '../../models/social_login_response.dart';

/// Implementation cụ thể của [AuthRepository].
/// Inject [AuthApi] để gọi API.
class ApiAuthRepository implements AuthRepository {
  final AuthApi _remoteSource;

  ApiAuthRepository(this._remoteSource);

  @override
  Future<LoginResponse> login(LoginRequest request) {
    return _remoteSource.login(request);
  }

  @override
  Future<RegisterResponse> register(RegisterRequest request) {
    return _remoteSource.register(request);
  }

  @override
  Future<SocialLoginResponse> socialLogin(SocialLoginRequest request) {
    return _remoteSource.socialLogin(request);
  }
}
