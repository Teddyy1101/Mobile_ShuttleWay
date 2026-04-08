import 'package:flutter/material.dart';
import '../../../data/repositories/leave_request_repository.dart';

class LeaveRequestController extends ChangeNotifier {
  final LeaveRequestRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  LeaveRequestController({required LeaveRequestRepository repository})
      : _repository = repository;

  Future<bool> createLeaveRequest({
    required BuildContext context,
    required String studentId,
    required String parentId,
    required String fromDate,
    required String toDate,
    String? reason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.createLeaveRequest(
        studentId: studentId,
        parentId: parentId,
        fromDate: fromDate,
        toDate: toDate,
        reason: reason,
      );
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký xin nghỉ thành công'), backgroundColor: Colors.green),
        );
      }
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }
}
