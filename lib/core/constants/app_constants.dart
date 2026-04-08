/// Hằng số dùng chung cho toàn bộ ứng dụng ShuttleWay.
class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'http://192.168.1.11:8080';

  // Assets
  static const String logoPath = 'assets/images/logo2.png';

  // App Info
  static const String appName = 'ShuttleWay';
  static const String appSubtitle =
      'Hệ thống đưa đón học sinh an toàn và\nthông minh';

  // UI Spacing
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  // Logo & Icon Sizes
  static const double logoSizeLG = 200.0;
  static const double logoSizeSM = 72.0;
  static const double iconSizeSM = 20.0;
  static const double iconSizeMD = 24.0;

  // Input
  static const double inputHeight = 56.0;
  static const double buttonHeight = 52.0;

  // Avatar
  static const double avatarSizeSM = 40.0;
  static const double avatarSizeMD = 48.0;
  static const double avatarSizeLG = 80.0;

  // Profile
  static const String appVersion = 'BUS SAFE APP - VERSION 1.0.1';
  static const double profileChildAvatarSize = 36.0;

  // Map
  static const double mapDefaultLat = 21.0285;
  static const double mapDefaultLng = 105.8542;
  static const double mapDefaultZoom = 14.0;
  static const double mapPreviewHeight = 180.0;

  // Quick Actions
  static const double quickActionSize = 52.0;

  // Bottom Nav
  static const double bottomNavHeight = 56.0;
  static const double bottomNavItemWidth = 64.0;

  // WebSocket
  static const String socketBaseUrl = 'http://192.168.1.11:8080';
}
