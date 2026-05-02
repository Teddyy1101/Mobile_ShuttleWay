class SocialLoginRequest {
  final String idToken;
  final String? role;
  final String? phone;

  SocialLoginRequest({
    required this.idToken,
    this.role,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'idToken': idToken,
    };
    if (role != null) {
      data['role'] = role;
    }
    if (phone != null) {
      data['phone'] = phone;
    }
    return data;
  }
}
