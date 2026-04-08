/// Model cho một hoạt động gần đây trên trang chủ phụ huynh.
/// Hiện tại dùng mock data, chờ backend bổ sung API activity log.
class ActivityModel {
  final String iconType;
  final String title;
  final String subtitle;
  final String time;

  const ActivityModel({
    required this.iconType,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
