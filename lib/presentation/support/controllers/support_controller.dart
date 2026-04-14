import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/support_repository.dart';

class SupportController extends ChangeNotifier {
  final SupportRepository _supportRepository;

  SupportController(this._supportRepository);

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Gửi phiếu yêu cầu hỗ trợ mới.
  /// Trả về true nếu thành công.
  Future<bool> submitTicket({
    required String userId,
    required String category,
    required String title,
    required String content,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supportRepository.createTicket(
        userId: userId,
        category: category,
        title: title,
        content: content,
      );
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isSubmitting = false;
      _errorMessage = _parseDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Đã xảy ra lỗi khi gửi phiếu hỗ trợ';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _parseDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Không thể kết nối đến server. Vui lòng thử lại';
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      final msg = data['message'];
      if (msg is List) return msg.join(', ');
      return msg?.toString() ?? 'Đã xảy ra lỗi';
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại';
  }
}
