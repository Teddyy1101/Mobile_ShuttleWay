# SafeWheels Mobile - Memory

## Kiến trúc
- Clean Architecture: `core/` → `data/` → `presentation/`
- State management: `ChangeNotifier` + `ListenableBuilder`
- DI thủ công trong `main.dart` (dự kiến chuyển `get_it`)
- Theme: hỗ trợ Light/Dark, dùng `colorScheme` từ context, không hardcode màu
- Constants: padding, radius, sizes trong `AppConstants`

## Auth Module
- **Login**: `LoginScreen` → `LoginFormWidget` + `SocialLoginWidget`
- **Register**: `RegisterScreen` → `RegisterFormWidget` + `RoleSelectorWidget`
- Controller: `AuthController` (ChangeNotifier) xử lý cả login + register
- Repository pattern: `AuthRepository` (abstract) → `ApiAuthRepository` (impl) → `AuthApi` (source)
- Models: `LoginRequest`, `LoginResponse`, `RegisterRequest`, `RegisterResponse`, `UserModel`
- API endpoints: `POST /auth/login`, `POST /auth/register`
- Role đăng ký: `parent` (Phụ huynh), `student` (Học sinh)
- Validation client-side: họ tên (không rỗng), email (regex), mật khẩu (≥6 ký tự), xác nhận mật khẩu (khớp)

## Quy tắc code (từ rule.md)
- File UI < 150 dòng → tách widget con
- Không hardcode string, padding, colors
- Dùng `Theme.of(context).colorScheme` cho màu sắc
- Try-catch khi gọi API, kiểm tra status code
- Null safety: dùng `?`, `??`, tránh `!`
- Doc comment `///` cho class và hàm phức tạp

## Map / Tracking Module (Real-time Bus Tracking)
- **Mục đích:** Hiển thị vị trí xe buýt real-time trên bản đồ. Dành cho PARENT & STUDENT. Tab thứ 2 (index 1) trong BottomNavBar.
- **Luồng hoạt động:**
  1. `MapController.loadActiveTrips()` → gọi `GET /trips/my-active-trips` → lấy trips IN_PROGRESS thuộc tuyến có vé ACTIVE.
  2. Tự động `selectTrip()` chuyến đầu tiên → decode polyline, sắp xếp trạm theo chiều (DROP_OFF đảo ngược), đặt bus ở trạm đầu.
  3. `SocketService.connect()` → join room `tripId` → listen `location_updated` event → cập nhật `currentBusPosition`.
  4. Khi không có chuyến active → hiển thị empty state "Xe chưa khởi hành" overlay lên bản đồ nền.
- **Data Layer:**
  - `TripModel` (`data/models/trip_model.dart`): TripModel, TripBusModel, TripDriverModel, TripRouteModel (kèm `encodedPolyline`), TripRouteStationModel, TripStationModel.
  - `TripApi` (`data/sources/trip_api.dart`): `getMyActiveTrips()`, `getTripTracking(tripId)`.
  - `TripRepository` (`data/repositories/trip_repository.dart`) → `ApiTripRepository` (`data/repositories/impl/trip_repository_impl.dart`).
- **Core:**
  - `SocketService` (`core/network/socket_service.dart`): Wrapper Socket.IO → namespace `/tracking`. Tự gắn Bearer token. Methods: `connect()`, `joinTrip(tripId)`, `onLocationUpdated()`, `onSimulationCompleted()`, `leaveTrip()`, `disconnect()`.
  - `PolylineDecoder` (`core/utils/polyline_decoder.dart`): Decode Google Encoded Polyline → `List<LatLng>`. Static method `decode(String?)`.
- **Presentation (`presentation/map/`):**
  - `MapController`: ChangeNotifier. State: activeTrips, selectedTrip, currentBusPosition, polylinePoints, orderedStations. Xử lý chiều đi/về (DROP_OFF reverse).
  - `MapScreen`: Full-screen FlutterMap. Polyline route, StationMarker layer, BusMarker layer. Top bar (refresh, fit-bounds). "Điểm tiếp theo" overlay card. DraggableScrollableSheet trip info.
  - `TripInfoSheetWidget`: Draggable bottom sheet. Header (route name, direction, bus plate), driver row, station timeline (passed/current/upcoming).
  - `StationMarkerWidget`: 3 states — `passed` (green), `current` (primary + glow), `upcoming` (grey).
  - `BusMarkerWidget`: Animated pulse ring + bus icon chip with license plate.
- **Navigation Integration:**
  - `ParentHomeScreen`: case 1 → `MapScreen(mapController)`. BusMapWidget "Mở rộng" → `setState(() => _currentNavIndex = 1)`.
  - `main.dart`: DI chain: `TripApi → ApiTripRepository → MapController(repo, socketService)`.
  - `mapController` truyền qua: `main.dart → SafeWheelsApp → LoginScreen → ParentHomeScreen → ProfileScreen (logout → LoginScreen)`.
- **Backend API tương ứng:**
  - `GET /trips/my-active-trips` → `TripsService.getMyActiveTrips(currentUser)`.
  - `POST /trips/:id/simulate` → `TripsService.simulateTrip(tripId)` — dùng tọa độ thực từ stations, nội suy 5 điểm giữa, hỗ trợ DROP_OFF reverse.
  - WebSocket `/tracking`: `join_trip`, `location_updated`, `simulation_completed`.
