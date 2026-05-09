import '../../models/login_response.dart';
import '../../models/child_model.dart';
import '../../models/transaction_model.dart';
import '../../models/ticket_model.dart';
import '../../sources/user_api.dart';
import '../../sources/transaction_api.dart';
import '../../sources/ticket_api.dart';
import '../profile_repository.dart';

/// Implementation của [ProfileRepository].
/// Gọi [UserApi], [TransactionApi] và [TicketApi] để thực hiện các thao tác profile.
class ApiProfileRepository implements ProfileRepository {
  final UserApi _userApi;
  final TransactionApi _transactionApi;
  final TicketApi _ticketApi;

  ApiProfileRepository(this._userApi, this._transactionApi, this._ticketApi);

  @override
  Future<UserModel> getProfile() => _userApi.getProfile();

  @override
  Future<List<ChildModel>> getMyChildren() => _userApi.getMyChildren();

  @override
  Future<List<ChildModel>> getMyParents() => _userApi.getMyParents();

  @override
  Future<TransactionListResponse> getMyTransactions({
    int page = 1,
    int limit = 20,
    String? fromDate,
    String? toDate,
  }) =>
      _transactionApi.getMyTransactions(
        page: page,
        limit: limit,
        fromDate: fromDate,
        toDate: toDate,
      );

  @override
  Future<TicketListResponse> getMyTickets({
    int page = 1,
    int limit = 20,
    String? ticketType,
    String? status,
  }) =>
      _ticketApi.getMyTickets(
        page: page,
        limit: limit,
        ticketType: ticketType,
        status: status,
      );

  @override
  Future<void> changePassword(String oldPassword, String newPassword) =>
      _userApi.changePassword(oldPassword, newPassword);

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarFilePath,
  }) =>
      _userApi.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarFilePath: avatarFilePath,
      );

  @override
  Future<void> linkStudent(String phone) => _userApi.linkStudent(phone);

  @override
  Future<void> linkParent(String phone) => _userApi.linkParent(phone);

  @override
  Future<void> unlinkStudent(String studentId) => _userApi.unlinkStudent(studentId);

  @override
  Future<void> unlinkParent(String parentId) => _userApi.unlinkParent(parentId);

  @override
  Future<void> linkSocial(String idToken) => _userApi.linkSocial(idToken);
}
