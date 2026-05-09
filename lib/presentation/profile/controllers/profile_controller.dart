import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/login_response.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/repositories/profile_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Controller quản lý state cho màn hình Cá nhân (Profile).
/// Sử dụng ChangeNotifier + ListenableBuilder pattern.
class ProfileController extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  final DioClient _dioClient;

  ProfileController(this._profileRepository, this._dioClient);

  // ─── State ────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _profile;
  List<ChildModel> _linkedUsers = [];
  List<TransactionModel> _transactions = [];
  int _transactionTotal = 0;
  int _transactionPage = 1;
  String? _currentFromDate;
  String? _currentToDate;
  List<TicketModel> _tickets = [];
  int _ticketTotal = 0;
  int _ticketPage = 1;
  bool _isChangingPassword = false;
  bool _isUpdatingProfile = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get profile => _profile;
  List<ChildModel> get linkedUsers => _linkedUsers;
  List<TransactionModel> get transactions => _transactions;
  int get transactionTotal => _transactionTotal;
  List<TicketModel> get tickets => _tickets;
  int get ticketTotal => _ticketTotal;
  bool get isChangingPassword => _isChangingPassword;
  bool get isUpdatingProfile => _isUpdatingProfile;

  /// Có phải phụ huynh hay không.
  bool get isParent => _profile?.role == 'PARENT';

  /// Gán profile từ thông tin đăng nhập (tránh gọi lại API /users/me).
  void setProfileFromLogin(UserModel user) {
    _profile = user;
    notifyListeners();
  }

  /// Load dữ liệu profile + danh sách liên kết.
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load profile nếu chưa có
      _profile ??= await _profileRepository.getProfile();

      // Load danh sách liên kết tuỳ role
      if (isParent) {
        _linkedUsers = await _profileRepository.getMyChildren();
      } else {
        _linkedUsers = await _profileRepository.getMyParents();
      }

      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
    }
  }

  /// Load lịch sử giao dịch (phân trang).
  Future<void> loadTransactions({
    bool refresh = false,
    String? fromDate,
    String? toDate,
  }) async {
    if (refresh) {
      _transactionPage = 1;
      _transactions = [];
      _currentFromDate = fromDate;
      _currentToDate = toDate;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileRepository.getMyTransactions(
        page: _transactionPage,
        limit: 20,
        fromDate: _currentFromDate,
        toDate: _currentToDate,
      );
      if (refresh) {
        _transactions = response.items;
      } else {
        _transactions = [..._transactions, ...response.items];
      }
      _transactionTotal = response.total;
      _transactionPage++;
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
    }
  }

  /// Load danh sách vé của tôi (phân trang, lọc).
  Future<void> loadMyTickets({
    bool refresh = false,
    String? ticketType,
    String? status,
  }) async {
    if (refresh) {
      _ticketPage = 1;
      _tickets = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _profileRepository.getMyTickets(
        page: _ticketPage,
        limit: 20,
        ticketType: ticketType,
        status: status,
      );
      if (refresh) {
        _tickets = response.items;
      } else {
        _tickets = [..._tickets, ...response.items];
      }
      _ticketTotal = response.total;
      _ticketPage++;
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
    }
  }

  /// Đổi mật khẩu.
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isChangingPassword = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.changePassword(oldPassword, newPassword);
      _isChangingPassword = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isChangingPassword = false;
      _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isChangingPassword = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật thông tin cá nhân (tên, SĐT, ảnh đại diện).
  /// Trả về `true` nếu thành công.
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? avatarFilePath,
  }) async {
    _isUpdatingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _profileRepository.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarFilePath: avatarFilePath,
      );
      _profile = updatedUser;
      _isUpdatingProfile = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isUpdatingProfile = false;
      _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isUpdatingProfile = false;
      _errorMessage = 'Đã xảy ra lỗi khi cập nhật thông tin';
      notifyListeners();
      return false;
    }
  }

  /// Liên kết tài khoản Google
  Future<bool> linkWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        await _profileRepository.linkSocial(idToken);
        // Load lại profile để cập nhật googleId
        _profile = await _profileRepository.getProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      _errorMessage = 'Không thể lấy ID Token từ Google';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi khi liên kết Google: $e';
      notifyListeners();
      return false;
    }
  }

  /// Liên kết tài khoản Facebook
  Future<bool> linkWithFacebook() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final idToken = await userCredential.user?.getIdToken();

        if (idToken != null) {
          await _profileRepository.linkSocial(idToken);
          // Load lại profile để cập nhật facebookId
          _profile = await _profileRepository.getProfile();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      
      _isLoading = false;
      if (result.status == LoginStatus.cancelled) return false;
      
      _errorMessage = 'Đăng nhập Facebook thất bại';
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi khi liên kết Facebook: $e';
      notifyListeners();
      return false;
    }
  }

  /// Liên kết học sinh/phụ huynh qua số điện thoại.
  /// Tự phân biệt role: PARENT → linkStudent, STUDENT → linkParent.
  /// Trả về `true` nếu thành công.
  Future<bool> linkByPhone(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isParent) {
        await _profileRepository.linkStudent(phone);
      } else {
        await _profileRepository.linkParent(phone);
      }

      // Reload danh sách liên kết
      if (isParent) {
        _linkedUsers = await _profileRepository.getMyChildren();
      } else {
        _linkedUsers = await _profileRepository.getMyParents();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
      return false;
    }
  }
  /// Hủy liên kết học sinh/phụ huynh.
  /// Tự phân biệt role: PARENT → unlinkStudent, STUDENT → unlinkParent.
  /// Trả về `true` nếu thành công.
  Future<bool> unlinkUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isParent) {
        await _profileRepository.unlinkStudent(userId);
      } else {
        await _profileRepository.unlinkParent(userId);
      }

      // Reload danh sách liên kết
      if (isParent) {
        _linkedUsers = await _profileRepository.getMyChildren();
      } else {
        _linkedUsers = await _profileRepository.getMyParents();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không xác định';
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất: xóa token + clear state.
  Future<void> logout() async {
    _dioClient.clearAccessToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _profile = null;
    _linkedUsers = [];
    _transactions = [];
    notifyListeners();
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Xử lý lỗi chung từ Dio.
  void _handleDioError(DioException e) {
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
  }
}
