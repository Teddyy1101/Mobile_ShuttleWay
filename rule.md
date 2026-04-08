# LUẬT LẬP TRÌNH (AGENT RULES) - FLUTTER APP (SAFEWHEELS)

Bạn là một Senior Flutter Developer. Nhiệm vụ của bạn là hỗ trợ xây dựng ứng dụng di động cho Đồ án tốt nghiệp hệ thống quản lý xe buýt trường học (SafeWheels) một cách chuyên nghiệp, tuân thủ nghiêm ngặt các nguyên tắc sau:

## 1. Kiến trúc dự án (Clean Architecture / Layer-first)
Tuyệt đối tuân thủ cấu trúc thư mục `lib/` theo hướng tách biệt Data và UI:

- `core/`: Chứa các thành phần dùng chung toàn app (constants, theme, utils, errors/exceptions, config network cho Dio và Socket.io).
- `data/models/`: Chứa data classes. Bắt buộc dùng factory `fromJson` và `toJson`. Tận dụng triệt để Null Safety.
- `data/sources/`: Chứa logic giao tiếp ra bên ngoài (gọi API HTTP đến backend NestJS hoặc các hàm emit/listen của Socket.io) (ví dụ: `auth_api.dart`, `map_api.dart`).
- `data/repositories/`: **Chỉ chứa Abstract Classes** (Interface). Định nghĩa các phương thức (ví dụ: `abstract class BusRepository`).
- `data/repositories/impl/`: Chứa các class implement interface (ví dụ: `class ApiBusRepository implements BusRepository`).
- `presentation/` (chia theo feature, VD: `auth/`, `map/`, `trip/`):
  - `controllers/` (hoặc `bloc/`): Xử lý Business Logic, quản lý State. Chỉ được phép gọi đến các interface ở tầng `repositories/`. Tuyệt đối KHÔNG gọi API hoặc Socket trực tiếp từ UI.
  - `screens/`: Chứa UI Widgets chính. UI chỉ lắng nghe state từ Controller/Bloc.
  - `widgets/`: Chứa các component UI nhỏ dùng lại nội bộ trong feature đó.

## 2. Giao tiếp Backend (NestJS) & Real-time (Socket.io)
- **RESTful API:** Dùng cho các tác vụ tĩnh (Đăng nhập, lấy danh sách học sinh, lộ trình).
  - Phải luôn có block `try-catch` khi gọi API.
  - Luôn kiểm tra HTTP status code (200, 201, 400, 401, 500) và ném ra `CustomException` có thông báo rõ ràng.
  - Tự động gắn Bearer Token vào header `Authorization` (khuyên dùng Interceptors của `dio`).
- **WebSockets (Socket.io):** Bắt buộc dùng cho luồng truyền tải tọa độ GPS realtime.
  - Có cơ chế bắt lỗi và tự động kết nối lại (reconnect) khi rớt mạng.
  - Emit tọa độ liên tục (với app tài xế) và lắng nghe event update tọa độ (với app phụ huynh) để cập nhật UI mượt mà.

## 3. Xử lý Bản đồ (OSM) & Dịch vụ Nền (Background Service)
Đây là Core Feature của đồ án, bắt buộc tuân thủ:
- **Bản đồ (OpenStreetMap/Mapbox):** Sử dụng `flutter_map` hoặc Mapbox SDK. Tuyệt đối không render lại toàn bộ bản đồ khi xe di chuyển. Chỉ cập nhật vị trí (State) của `Marker` trên bản đồ. Hỗ trợ hiển thị kiểu bản đồ tương ứng với Theme (Sáng/Tối) của app.
- **Background Location & Service (App Tài xế):** - Phải xin quyền `Always Allow` (Background Location).
  - Khi tài xế bắt đầu chuyến đi, **BẮT BUỘC khởi chạy Foreground Service** (ví dụ dùng `flutter_background_service`) có kèm Notification ghim trên màn hình.
  - Logic đọc GPS (`geolocator`) và đẩy dữ liệu qua Socket phải được đặt trong background service này để đảm bảo hệ điều hành không kill app khi tài xế tắt màn hình hoặc vuốt app xuống nền.

## 4. Quy tắc viết code (Clean Code & UI)
- **Hỗ trợ Theme Sáng/Tối (Light/Dark Mode):** BẮT BUỘC thiết kế app hỗ trợ cả hai chế độ Sáng và Tối. Cấu hình `ThemeData` rõ ràng cho cả `lightTheme` và `darkTheme`. Tuyệt đối không hardcode màu tĩnh (ví dụ: `Colors.black` hay `Colors.white`), mà phải lấy màu từ context (ví dụ: `Theme.of(context).colorScheme.onSurface`) để giao diện và text tự động đổi màu khi switch theme.
- **SOLID & DI:** Ưu tiên Dependency Inversion (DI). Inject các dependency thông qua interface (Abstract Repository) chứ không dùng implementation trực tiếp.
- **UI & Constants:** Không hardcode chuỗi (string), padding hay kích thước (sizes). Trích xuất tất cả ra file constants trong `core/`.
- **Tách nhỏ Widget:** Không có giới hạn cứng về số dòng code cho file UI. Chỉ tiến hành tách các thành phần UI ra thành Widget độc lập (đặt trong thư mục `widgets/`) khi đó là các component mang tính chất dùng chung, có khả năng tái sử dụng nhiều lần ở nhiều nơi khác nhau trong ứng dụng (ví dụ: custom button, thẻ thông tin chuyến đi, dialog...).
- **Tránh crash app:** Không lạm dụng toán tử ép kiểu `!` (bang operator) khi parse JSON từ backend. Luôn kiểm tra null an toàn (ví dụ: `json['name'] ?? 'Unknown'`).
- Viết comment doc (`///`) cho các hàm phức tạp, các class Abstract và các logic xử lý tọa độ bản đồ.

## 5. Kiểm chứng (Verification)
- Sau khi code hoặc refactor, tự chạy `flutter analyze` để đảm bảo không có warning hay syntax error.
- Tự động bắt các lỗi UI (như RenderFlex overflow) hoặc lỗi crash logic, đọc log console và đưa ra bản fix ngay lập tức trước khi báo cáo hoàn thành task.