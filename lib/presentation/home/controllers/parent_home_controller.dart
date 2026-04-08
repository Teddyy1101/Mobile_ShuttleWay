import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../data/models/login_response.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/repositories/parent_repository.dart';

/// Controller quản lý state cho trang chủ phụ huynh.
/// Sử dụng ChangeNotifier + ListenableBuilder pattern.
class ParentHomeController extends ChangeNotifier {
  final ParentRepository _parentRepository;

  ParentHomeController(this._parentRepository);

  // ─── State ────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _profile;
  List<ChildModel> _children = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get profile => _profile;
  List<ChildModel> get children => _children;

  /// Có học sinh nào đã liên kết chưa.
  bool get hasChildren => _children.isNotEmpty;

  /// Mock data hoạt động gần đây (chờ backend bổ sung API).
  List<ActivityModel> get recentActivities => const [
        ActivityModel(
          iconType: 'boarded',
          title: 'Bé đã lên xe',
          subtitle: 'Tại điểm đón: Chung cư Times City',
          time: '07:05',
        ),
        ActivityModel(
          iconType: 'bus_arriving',
          title: 'Xe buýt sắp đến',
          subtitle: 'Xe 29B-123.45 cách điểm đón 500m',
          time: '06:55',
        ),
        ActivityModel(
          iconType: 'attendance',
          title: 'Điểm danh thành công',
          subtitle: 'Bé được đón bởi Bố',
          time: 'Hôm qua',
        ),
      ];

  /// Lời chào theo giờ trong ngày.
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng,';
    if (hour < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }

  /// Gán profile từ thông tin đăng nhập (tránh gọi lại API /users/me).
  void setProfileFromLogin(UserModel user) {
    _profile = user;
    notifyListeners();
  }

  /// Load danh sách học sinh liên kết.
  Future<void> loadData() async {
    if (_profile?.role != 'PARENT') {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _children = await _parentRepository.getMyChildren();
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.statusCode == 401) {
        _errorMessage = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _errorMessage = 'Không thể kết nối đến server. Vui lòng thử lại';
      } else {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          final msg = data['message'];
          if (msg is List) {
            _errorMessage = msg.join(', ');
          } else {
            _errorMessage = msg?.toString() ?? 'Đã xảy ra lỗi';
          }
        } else {
          _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại';
        }
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
    }
  }

  /// Liên kết phụ huynh với học sinh qua số điện thoại.
  Future<bool> linkStudent(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _parentRepository.linkStudent(phone);
      // Reload danh sách children sau khi liên kết thành công
      _children = await _parentRepository.getMyChildren();
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        final msg = data['message'];
        if (msg is List) {
          _errorMessage = msg.join(', ');
        } else {
          _errorMessage = msg?.toString() ?? 'Đã xảy ra lỗi';
        }
      } else if (e.response?.statusCode == 404) {
        _errorMessage = 'Không tìm thấy học sinh với số điện thoại này';
      } else if (e.response?.statusCode == 409) {
        _errorMessage = 'Liên kết với học sinh này đã tồn tại';
      } else {
        _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
      return false;
    }
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
