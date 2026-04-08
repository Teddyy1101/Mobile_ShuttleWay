import '../../models/login_response.dart';
import '../../models/child_model.dart';
import '../../sources/parent_api.dart';
import '../parent_repository.dart';

/// Implementation của [ParentRepository].
/// Gọi [ParentApi] để thực hiện các thao tác liên quan đến phụ huynh.
class ApiParentRepository implements ParentRepository {
  final ParentApi _parentApi;

  ApiParentRepository(this._parentApi);

  @override
  Future<UserModel> getProfile() => _parentApi.getProfile();

  @override
  Future<List<ChildModel>> getMyChildren() => _parentApi.getMyChildren();

  @override
  Future<void> linkStudent(String phone) => _parentApi.linkStudent(phone);
}
