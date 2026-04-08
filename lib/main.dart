import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/network/dio_client.dart';
import 'core/network/socket_service.dart';
import 'data/sources/auth_api.dart';
import 'data/sources/parent_api.dart';
import 'data/sources/user_api.dart';
import 'data/sources/transaction_api.dart';
import 'data/sources/promotion_api.dart';
import 'data/sources/ticket_api.dart';
import 'data/sources/route_api.dart';
import 'data/sources/trip_api.dart';
import 'data/repositories/impl/auth_repository_impl.dart';
import 'data/repositories/impl/parent_repository_impl.dart';
import 'data/repositories/impl/profile_repository_impl.dart';
import 'data/repositories/impl/ticket_repository_impl.dart';
import 'data/repositories/impl/payment_repository_impl.dart';
import 'data/repositories/impl/promotion_repository_impl.dart';
import 'data/repositories/impl/trip_repository_impl.dart';
import 'data/repositories/impl/api_leave_request_repository.dart';
import 'presentation/auth/controllers/auth_controller.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/home/controllers/parent_home_controller.dart';
import 'presentation/map/controllers/map_controller.dart';
import 'presentation/profile/controllers/profile_controller.dart';
import 'presentation/ticket/controllers/ticket_controller.dart';
import 'presentation/ticket/controllers/payment_controller.dart';
import 'presentation/home/controllers/leave_request_controller.dart';
import 'presentation/home/controllers/schedule_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi');

  // ─── Theme ──
  final themeController = ThemeController();
  await themeController.loadSavedTheme();

  // ─── Manual DI (tạm thời, sau chuyển sang get_it) ──
  final dioClient = await DioClient.create();
  final authApi = AuthApi(dioClient);
  final authRepository = ApiAuthRepository(authApi);
  final authController = AuthController(authRepository, dioClient);

  final parentApi = ParentApi(dioClient);
  final parentRepository = ApiParentRepository(parentApi);
  final parentHomeController = ParentHomeController(parentRepository);

  final userApi = UserApi(dioClient);
  final transactionApi = TransactionApi(dioClient);
  final ticketApi = TicketApi(dioClient);
  final profileRepository = ApiProfileRepository(userApi, transactionApi, ticketApi);
  final profileController = ProfileController(profileRepository, dioClient);

  final routeApi = RouteApi(dioClient);
  final ticketRepository = ApiTicketRepository(routeApi, ticketApi);
  final ticketController = TicketController(ticketRepository);

  final paymentRepository = ApiPaymentRepository(transactionApi);
  final promotionApi = PromotionApi(dioClient);
  final promotionRepository = ApiPromotionRepository(promotionApi);
  final paymentController = PaymentController(paymentRepository, promotionRepository);

  final tripApi = TripApi(dioClient);
  final tripRepository = ApiTripRepository(tripApi);
  final socketService = SocketService();
  final mapController = MapController(tripRepository, socketService);

  // ─── Schedule & Leave Request ──
  final leaveRequestRepository = ApiLeaveRequestRepository(dioClient.dio);
  final leaveRequestController = LeaveRequestController(repository: leaveRequestRepository);
  final scheduleController = ScheduleController(tripRepository: tripRepository);

  runApp(SafeWheelsApp(
    themeController: themeController,
    authController: authController,
    parentHomeController: parentHomeController,
    profileController: profileController,
    ticketController: ticketController,
    paymentController: paymentController,
    mapController: mapController,
    leaveRequestController: leaveRequestController,
    scheduleController: scheduleController,
  ));
}

/// Root widget của ứng dụng SafeWheels.
class SafeWheelsApp extends StatefulWidget {
  final ThemeController themeController;
  final AuthController authController;
  final ParentHomeController parentHomeController;
  final ProfileController profileController;
  final TicketController ticketController;
  final PaymentController paymentController;
  final MapController mapController;
  final LeaveRequestController leaveRequestController;
  final ScheduleController scheduleController;

  const SafeWheelsApp({
    super.key,
    required this.themeController,
    required this.authController,
    required this.parentHomeController,
    required this.profileController,
    required this.ticketController,
    required this.paymentController,
    required this.mapController,
    required this.leaveRequestController,
    required this.scheduleController,
  });

  @override
  State<SafeWheelsApp> createState() => _SafeWheelsAppState();
}

class _SafeWheelsAppState extends State<SafeWheelsApp> {
  @override
  void initState() {
    super.initState();
    widget.themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeWheels',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: widget.themeController.themeMode,
      home: LoginScreen(
        authController: widget.authController,
        parentHomeController: widget.parentHomeController,
        profileController: widget.profileController,
        themeController: widget.themeController,
        ticketController: widget.ticketController,
        paymentController: widget.paymentController,
        mapController: widget.mapController,
        leaveRequestController: widget.leaveRequestController,
        scheduleController: widget.scheduleController,
      ),
    );
  }
}
