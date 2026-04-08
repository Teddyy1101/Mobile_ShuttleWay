abstract class LeaveRequestRepository {
  /// Gửi đơn xin nghỉ
  /// [studentId]: ID học sinh xin nghỉ
  /// [parentId]: ID phụ huynh (nếu là tài khoản phụ huynh)
  /// [fromDate]: Ngày bắt đầu nghỉ (kèm giờ)
  /// [toDate]: Ngày kết thúc nghỉ (kèm giờ)
  /// [reason]: Lý do xin nghỉ (optional)
  Future<void> createLeaveRequest({
    required String studentId,
    required String parentId,
    required String fromDate,
    required String toDate,
    String? reason,
  });
}
