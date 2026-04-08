/// Model thông tin trạm dừng.
class StationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const StationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Model trạm trên tuyến đường (bao gồm thứ tự).
class RouteStationModel {
  final int orderIndex;
  final StationModel station;

  const RouteStationModel({
    required this.orderIndex,
    required this.station,
  });

  factory RouteStationModel.fromJson(Map<String, dynamic> json) {
    return RouteStationModel(
      orderIndex: json['orderIndex'] as int? ?? 0,
      station: StationModel.fromJson(
        json['station'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// Model thông tin tuyến đường.
class RouteModel {
  final String id;
  final String routeCode;
  final String name;
  final String shiftType;
  final double singlePrice;
  final double monthlyPrice;
  final bool isActive;
  final double? totalDistance;
  final int? totalDuration;
  final String? estimatedTime;
  final List<RouteStationModel> stations;

  const RouteModel({
    required this.id,
    required this.routeCode,
    required this.name,
    required this.shiftType,
    required this.singlePrice,
    required this.monthlyPrice,
    this.isActive = true,
    this.totalDistance,
    this.totalDuration,
    this.estimatedTime,
    this.stations = const [],
  });

  /// Trạm đầu tiên (điểm đón).
  StationModel? get firstStation =>
      stations.isNotEmpty ? stations.first.station : null;

  /// Trạm cuối cùng (điểm trả).
  StationModel? get lastStation =>
      stations.isNotEmpty ? stations.last.station : null;

  /// Giờ khởi hành dạng HH:mm (parse từ ISO-8601 hoặc HH:mm:ss).
  String? get formattedStartTime {
    if (estimatedTime == null) return null;
    try {
      final dt = DateTime.parse(estimatedTime!);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      // Nếu đã là dạng HH:mm hoặc HH:mm:ss
      final parts = estimatedTime!.split(':');
      if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
      return null;
    }
  }

  /// Giờ kết thúc dự kiến = estimatedTime + totalDuration (phút).
  String? get formattedEndTime {
    if (estimatedTime == null || totalDuration == null) return null;
    try {
      final dt = DateTime.parse(estimatedTime!);
      final end = dt.add(Duration(minutes: totalDuration!));
      return '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      final parts = estimatedTime!.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final totalMinutes = hour * 60 + minute + totalDuration!;
        final endH = (totalMinutes ~/ 60) % 24;
        final endM = totalMinutes % 60;
        return '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
      }
      return null;
    }
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final stationsList = json['routeStations'] as List<dynamic>? ?? [];
    return RouteModel(
      id: json['id'] as String? ?? '',
      routeCode: json['routeCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shiftType: json['shiftType'] as String? ?? 'MORNING',
      singlePrice: (json['singlePrice'] as num?)?.toDouble() ?? 0,
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
      totalDuration: json['totalDuration'] as int?,
      estimatedTime: json['estimatedTime'] as String?,
      stations: stationsList
          .map((e) => RouteStationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
