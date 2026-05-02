import 'login_response.dart';

class SocialLoginResponse {
  final bool requiresAdditionalInfo;
  final String message;
  final LoginResponse? loginData;
  final String? email;
  final String? fullName;

  SocialLoginResponse({
    required this.requiresAdditionalInfo,
    required this.message,
    this.loginData,
    this.email,
    this.fullName,
  });

  factory SocialLoginResponse.fromJson(Map<String, dynamic> json) {
    // If backend returns 202, usually our HTTP client might handle it.
    // Assuming interceptor doesn't alter requiresAdditionalInfo if it's at root level.
    // Or it might be inside 'data' if wrapped by Interceptor.
    // Let's check both root and 'data' just in case.
    final data = json['data'] ?? json;
    
    final requiresInfo = data['requiresAdditionalInfo'] == true || json['requiresAdditionalInfo'] == true;
    
    if (requiresInfo) {
      return SocialLoginResponse(
        requiresAdditionalInfo: true,
        message: json['message'] ?? data['message'] ?? '',
        email: data['email'] ?? json['email'],
        fullName: data['fullName'] ?? json['fullName'],
      );
    } else {
      return SocialLoginResponse(
        requiresAdditionalInfo: false,
        message: json['message'] ?? '',
        loginData: LoginResponse.fromJson(json),
      );
    }
  }
}
