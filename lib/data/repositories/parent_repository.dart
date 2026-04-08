import '../models/login_response.dart';
import '../models/child_model.dart';

/// Interface (Abstract class) cho Parent Repository.
/// Tất cả các tầng trên (Controller/Bloc) chỉ gọi qua interface này
/// để tuân thủ Dependency Inversion Principle.
abstract class ParentRepository {
  /// Lấy thông tin cá nhân phụ huynh đang đăng nhập.
  Future<UserModel> getProfile();

  /// Lấy danh sách học sinh liên kết với phụ huynh.
  Future<List<ChildModel>> getMyChildren();

  /// Liên kết phụ huynh với học sinh qua số điện thoại.
  Future<void> linkStudent(String phone);
}
