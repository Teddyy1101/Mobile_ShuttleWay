import '../models/login_response.dart';
import '../models/child_model.dart';
import '../models/transaction_model.dart';
import '../models/ticket_model.dart';

/// Interface (Abstract class) cho Profile Repository.
/// Tất cả các tầng trên (Controller/Bloc) chỉ gọi qua interface này
/// để tuân thủ Dependency Inversion Principle.
abstract class ProfileRepository {
  /// Lấy thông tin cá nhân user đang đăng nhập.
  Future<UserModel> getProfile();

  /// Lấy danh sách học sinh liên kết (dành cho PARENT).
  Future<List<ChildModel>> getMyChildren();

  /// Lấy danh sách phụ huynh liên kết (dành cho STUDENT).
  Future<List<ChildModel>> getMyParents();

  /// Lấy lịch sử giao dịch thanh toán (phân trang).
  Future<TransactionListResponse> getMyTransactions({
    int page = 1,
    int limit = 20,
    String? fromDate,
    String? toDate,
  });

  /// Lấy danh sách vé của tôi (phân trang, lọc).
  Future<TicketListResponse> getMyTickets({
    int page = 1,
    int limit = 20,
    String? ticketType,
    String? status,
  });

  /// Đổi mật khẩu.
  Future<void> changePassword(String oldPassword, String newPassword);

  /// Cập nhật thông tin cá nhân (tên, SĐT, ảnh đại diện).
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarFilePath,
  });

  /// Phụ huynh liên kết với học sinh qua SĐT.
  Future<void> linkStudent(String phone);

  /// Học sinh liên kết với phụ huynh qua SĐT.
  Future<void> linkParent(String phone);

  /// Phụ huynh hủy liên kết với học sinh.
  Future<void> unlinkStudent(String studentId);

  /// Học sinh hủy liên kết với phụ huynh.
  Future<void> unlinkParent(String parentId);

  /// Liên kết mạng xã hội (Google/Facebook).
  Future<void> linkSocial(String idToken);
}

