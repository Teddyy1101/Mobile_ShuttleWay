import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/fcm_service.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/network/notification_socket_service.dart';
import '../../../data/models/notification_model.dart';
import '../controllers/auth_controller.dart';
import '../../home/controllers/parent_home_controller.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../../home/controllers/leave_request_controller.dart';
import '../../home/controllers/schedule_controller.dart';
import '../../home/controllers/driver_schedule_controller.dart';
import '../../home/screens/parent_home_screen.dart';
import '../../home/screens/driver_home_screen.dart';
import '../../map/controllers/map_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../ticket/controllers/ticket_controller.dart';
import '../../ticket/controllers/payment_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../home/controllers/chatbot_controller.dart';
import '../widgets/login_form_widget.dart';
import '../widgets/social_login_widget.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Màn hình đăng nhập chính của ứng dụng SafeWheels.
class LoginScreen extends StatefulWidget {
  final AuthController authController;
  final ParentHomeController parentHomeController;
  final DriverHomeController driverHomeController;
  final ProfileController profileController;
  final ThemeController themeController;
  final TicketController ticketController;
  final PaymentController paymentController;
  final MapController mapController;
  final LeaveRequestController leaveRequestController;
  final ScheduleController scheduleController;
  final DriverScheduleController driverScheduleController;
  final NotificationController notificationController;
  final ChatbotController chatbotController;
  final FcmService fcmService;
  final DioClient dioClient;
  final SocketService socketService;
  final NotificationSocketService notificationSocketService;

  const LoginScreen({
    super.key,
    required this.authController,
    required this.parentHomeController,
    required this.driverHomeController,
    required this.profileController,
    required this.themeController,
    required this.ticketController,
    required this.paymentController,
    required this.mapController,
    required this.leaveRequestController,
    required this.scheduleController,
    required this.driverScheduleController,
    required this.notificationController,
    required this.chatbotController,
    required this.fcmService,
    required this.dioClient,
    required this.socketService,
    required this.notificationSocketService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.authController.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Gán profile từ thông tin đăng nhập (tránh gọi lại API /users/me)
      final user = widget.authController.user;
      if (user != null) {
        widget.parentHomeController.setProfileFromLogin(user);
        widget.profileController.setProfileFromLogin(user);
        // Gán profile cho driver controller nếu role DRIVER
        if (user.role == 'DRIVER') {
          widget.driverHomeController.setProfileFromLogin(user);
        }
      }

      // Đăng ký FCM token + kết nối notification socket (fire-and-forget)
      widget.fcmService.registerToken(widget.dioClient).then((_) {
        // Lắng nghe token refresh → gửi lại lên server
        widget.fcmService.onTokenRefresh((newToken) {
          widget.dioClient.dio.patch('/users/me', data: {'fcmToken': newToken});
        });
      });

      // Kết nối Socket.IO notification + lắng nghe realtime
      widget.notificationSocketService.connect().then((_) {
        final userId = user?.id ?? '';
        if (userId.isNotEmpty) {
          widget.notificationSocketService.joinNotifications(userId);
          widget.notificationSocketService.onNewNotification((data) {
            final notification = NotificationModel.fromJson(data);
            widget.notificationController.onNewNotificationReceived(notification);
          });
        }
      });

      // Lắng nghe FCM foreground → chèn vào controller
      widget.fcmService.onForegroundMessage((title, body) {
        widget.notificationController.loadNotifications(refresh: true);
      });

      // Chuyển hướng theo role
      final isDriver = user?.role == 'DRIVER';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isDriver
              ? DriverHomeScreen(
                  driverHomeController: widget.driverHomeController,
                  parentHomeController: widget.parentHomeController,
                  profileController: widget.profileController,
                  authController: widget.authController,
                  themeController: widget.themeController,
                  ticketController: widget.ticketController,
                  paymentController: widget.paymentController,
                  mapController: widget.mapController,
                  leaveRequestController: widget.leaveRequestController,
                  scheduleController: widget.scheduleController,
                  driverScheduleController: widget.driverScheduleController,
                  notificationController: widget.notificationController,
                  chatbotController: widget.chatbotController,
                  fcmService: widget.fcmService,
                  dioClient: widget.dioClient,
                  socketService: widget.socketService,
                  notificationSocketService: widget.notificationSocketService,
                )
              : ParentHomeScreen(
                  controller: widget.parentHomeController,
                  driverHomeController: widget.driverHomeController,
                  profileController: widget.profileController,
                  authController: widget.authController,
                  themeController: widget.themeController,
                  ticketController: widget.ticketController,
                  paymentController: widget.paymentController,
                  mapController: widget.mapController,
                  leaveRequestController: widget.leaveRequestController,
                  scheduleController: widget.scheduleController,
                  driverScheduleController: widget.driverScheduleController,
                  notificationController: widget.notificationController,
                  chatbotController: widget.chatbotController,
                  fcmService: widget.fcmService,
                  dioClient: widget.dioClient,
                  socketService: widget.socketService,
                  notificationSocketService: widget.notificationSocketService,
                ),
        ),
      );
    } else {
      final error = widget.authController.errorMessage;
      if (error != null) {
        AppToast.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Đăng nhập',
          style: TextStyle(color: colorScheme.onSurface),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.authController,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLG,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppConstants.paddingMD),
                _buildLogo(colorScheme),
                const SizedBox(height: AppConstants.paddingXL),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: LoginFormWidget(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    onTogglePassword: _togglePasswordVisibility,
                    onForgotPassword: () {
                      widget.authController.clearError();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                            authController: widget.authController,
                          ),
                        ),
                      );
                    },
                    formKey: _formKey,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSM),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _buildLoginButton(colorScheme),
                ),
                const SizedBox(height: AppConstants.paddingXL),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: const SocialLoginWidget(),
                ),
                const SizedBox(height: AppConstants.paddingXL),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _buildRegisterLink(colorScheme),
                ),
                const SizedBox(height: AppConstants.paddingXL),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Logo + tên app + subtitle.
  Widget _buildLogo(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-30, -10),
            child: Image.asset(
              AppConstants.logoPath,
              width: AppConstants.logoSizeLG * 1.5,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          Transform.translate(
            offset: const Offset(0, -20),
            child: Text(
              AppConstants.appName,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSM),
          Transform.translate(
            offset: const Offset(0, -20),
            child: Text(
              AppConstants.appSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(153),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Nút Đăng nhập.
  Widget _buildLoginButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.authController.isLoading ? null : _handleLogin,
        child: widget.authController.isLoading
            ? SizedBox(
                width: AppConstants.iconSizeMD,
                height: AppConstants.iconSizeMD,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.onPrimary,
                ),
              )
            : const Text('Đăng nhập'),
      ),
    );
  }

  /// Link "Chưa có tài khoản? Đăng ký ngay".
  Widget _buildRegisterLink(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: TextStyle(
            color: colorScheme.onSurface.withAlpha(153),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            widget.authController.clearError();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RegisterScreen(
                  authController: widget.authController,
                ),
              ),
            );
          },
          child: Text(
            'Đăng ký ngay',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
