# KỸ NĂNG VÀ CÔNG NGHỆ (AGENT SKILLS) - FLUTTER APP (SAFEWHEELS)

Bạn là một chuyên gia lập trình Flutter. Để hoàn thành xuất sắc hệ thống quản lý xe buýt SafeWheels, bạn cần thành thạo và áp dụng đúng bộ công nghệ/thư viện dưới đây:

## 1. Ngôn ngữ & Nền tảng
- **Dart & Flutter SDK:** Sử dụng phiên bản Flutter mới nhất (3.x trở lên).
- **Sound Null Safety:** Nắm vững và áp dụng triệt để Null Safety. Khai báo biến rõ ràng (`?`, `late`, `required`). Hạn chế tối đa việc ép kiểu bằng dấu `!`.
- **Lập trình Bất đồng bộ (Asynchronous Programming):** Thành thạo `Future`, `Stream`, `async/await` để xử lý mượt mà các luồng dữ liệu thời gian thực và gọi API.

## 2. Quản lý Trạng thái & Kiến trúc (State Management & Architecture)
- **Kiến trúc:** Clean Architecture (tinh gọn) kết hợp Layer-first (như đã định nghĩa trong `rule.md`). Nắm vững Repository Pattern (Interface -> Implementation).
- **State Management:** (Chọn 1 trong 2 thư viện chính sau tùy theo setup của project)
  - `flutter_bloc` / `bloc`: Sử dụng BLoC/Cubit để tách biệt hoàn toàn Business Logic khỏi UI.
  - `flutter_riverpod`: Quản lý state an toàn, dễ scale và tự động dọn dẹp bộ nhớ.
- **Dependency Injection (DI):** Sử dụng `get_it` kết hợp `injectable` (hoặc Provider/Riverpod) để inject các Repository và Service vào Controller/Bloc.

## 3. Giao tiếp Backend (NestJS) & Real-time
- **RESTful API:** Sử dụng `dio` làm HTTP Client chính. 
  - Biết cách setup Interceptors để tự động gắn Bearer Token và xử lý lỗi global (ví dụ: tự động log out khi token hết hạn - 401).
- **WebSockets:** Sử dụng `socket_io_client`.
  - Khả năng xử lý các event realtime, quản lý vòng đời kết nối (connect, disconnect, reconnecting) đồng bộ với trạng thái của app.
- **Xử lý JSON:** Thành thạo sử dụng `json_serializable` và `build_runner` để tự động generate code `fromJson`/`toJson` cho các Models, tránh lỗi parse tay.

## 4. Bản đồ & Vị trí (Core Features)
- **Bản đồ (Maps):** Sử dụng `flutter_map` (dành cho OpenStreetMap) hoặc bộ SDK của `Mapbox`. Biết cách render `Marker` (icon xe buýt) và vẽ tuyến đường (`Polyline`) mà không làm nghẽn UI.
- **Định vị GPS:** Sử dụng `geolocator` để lấy tọa độ chính xác cao. Biết cách xử lý xin quyền (Permissions) trên cả iOS và Android (cần request `Always Allow`).
- **Dịch vụ chạy ngầm:** Sử dụng `flutter_background_service`. Có kỹ năng thiết lập thông báo Foreground (Foreground Notification) để giữ app tài xế luôn sống và liên tục bắn tọa độ lên server NestJS khi tắt màn hình.

## 5. UI/UX & Tối ưu hóa
- **Routing:** Sử dụng `go_router` hoặc `auto_route` để quản lý điều hướng, truyền tham số an toàn (type-safe) và xử lý Deep Link nếu cần.
- **Giao diện đáp ứng (Responsive UI):** Sử dụng `flutter_screenutil` hoặc các kỹ thuật dùng `LayoutBuilder`, `MediaQuery` để app hiển thị đẹp trên nhiều kích thước màn hình điện thoại khác nhau.
- **Hiệu năng:** Biết cách sử dụng `const` constructor, tránh rebuild UI không cần thiết với `Selector` hoặc `BlocBuilder` được chỉ định đúng state.

## 6. Lưu trữ cục bộ (Local Storage)
- Sử dụng `shared_preferences` hoặc `flutter_secure_storage` để lưu trữ an toàn JWT Token, thông tin user cơ bản và trạng thái chuyến đi hiện tại (để phục hồi nếu app lỡ bị crash).