class TripBusModel {
  final String id;
  final String licensePlate;
  final int seatCapacity;
  final String status;

  const TripBusModel({
    required this.id,
    required this.licensePlate,
    required this.seatCapacity,
    this.status = 'ACTIVE',
  });

  factory TripBusModel.fromJson(Map<String, dynamic> json) {
    return TripBusModel(
      id: json['id'] as String? ?? '',
      licensePlate: json['licensePlate'] as String? ?? '',
      seatCapacity: json['seatCapacity'] as int? ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

/// Model thông tin tài xế trong chuyến đi.
class TripDriverModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? avatarUrl;

  const TripDriverModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.avatarUrl,
  });

  factory TripDriverModel.fromJson(Map<String, dynamic> json) {
    return TripDriverModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

/// Model chuyến đi thực tế.
/// Parse từ response `GET /trips/my-active-trips` và `GET /trips/my-schedule`.
class TripModel {
  final String id;
  final String routeId;
  final String? busId;
  final String? driverId;
  final String direction;
  final String status;
  final int currentStation;
  final DateTime? scheduledDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final TripRouteModel? route;
  final TripBusModel? bus;
  final TripDriverModel? driver;

  /// Số học sinh được gắn vào chuyến (từ `_count.attendances`).
  final int attendanceCount;

  /// Trạng thái điểm danh cá nhân (PENDING / BOARDED / ALIGHTED / ABSENT).
  /// Chỉ có khi gọi từ API my-schedule.
  final String? attendanceStatus;
  final DateTime? boardedAt;
  final DateTime? alightedAt;

  const TripModel({
    required this.id,
    required this.routeId,
    this.busId,
    this.driverId,
    required this.direction,
    required this.status,
    this.currentStation = 0,
    this.scheduledDate,
    this.startTime,
    this.endTime,
    this.route,
    this.bus,
    this.driver,
    this.attendanceCount = 0,
    this.attendanceStatus,
    this.boardedAt,
    this.alightedAt,
  });

  /// Có phải chiều về (DROP_OFF) không.
  bool get isDropOff => direction == 'DROP_OFF';

  factory TripModel.fromJson(Map<String, dynamic> json) {
    // Parse _count.attendances từ Prisma include
    final countMap = json['_count'] as Map<String, dynamic>?;
    final attendances = countMap?['attendances'] as int? ?? 0;

    return TripModel(
      id: json['id'] as String? ?? '',
      routeId: json['routeId'] as String? ?? '',
      busId: json['busId'] as String?,
      driverId: json['driverId'] as String?,
      direction: json['direction'] as String? ?? 'PICK_UP',
      status: json['status'] as String? ?? 'PENDING',
      currentStation: json['currentStation'] as int? ?? 0,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'] as String)
          : null,
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
      route: json['route'] != null
          ? TripRouteModel.fromJson(json['route'] as Map<String, dynamic>)
          : null,
      bus: json['bus'] != null
          ? TripBusModel.fromJson(json['bus'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null
          ? TripDriverModel.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      attendanceCount: attendances,
      attendanceStatus: json['attendanceStatus'] as String?,
      boardedAt: json['boardedAt'] != null
          ? DateTime.tryParse(json['boardedAt'] as String)
          : null,
      alightedAt: json['alightedAt'] != null
          ? DateTime.tryParse(json['alightedAt'] as String)
          : null,
    );
  }
}

/// Model tuyến đường kèm trạm dừng (dùng trong Trip).
/// Bao gồm encodedPolyline để vẽ tuyến trên bản đồ.
class TripRouteModel {
  final String id;
  final String routeCode;
  final String name;
  final String shiftType;
  final double? totalDistance;
  final int? totalDuration;
  final String? encodedPolyline;

  /// Giờ xuất phát lý thuyết (từ bảng Route.estimatedTime).
  /// Prisma trả về dạng ISO string, chỉ cần phần giờ:phút.
  final DateTime? estimatedTime;

  final List<TripRouteStationModel> stations;

  const TripRouteModel({
    required this.id,
    required this.routeCode,
    required this.name,
    required this.shiftType,
    this.totalDistance,
    this.totalDuration,
    this.encodedPolyline,
    this.estimatedTime,
    this.stations = const [],
  });

  factory TripRouteModel.fromJson(Map<String, dynamic> json) {
    final stationsList = json['routeStations'] as List<dynamic>? ?? [];
    return TripRouteModel(
      id: json['id'] as String? ?? '',
      routeCode: json['routeCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shiftType: json['shiftType'] as String? ?? 'MORNING',
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
      totalDuration: json['totalDuration'] as int?,
      encodedPolyline: json['encodedPolyline'] as String?,
      estimatedTime: json['estimatedTime'] != null
          ? DateTime.tryParse(json['estimatedTime'] as String)
          : null,
      stations: stationsList
          .map((e) =>
              TripRouteStationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Model trạm trên tuyến (dùng trong TripRouteModel).
class TripRouteStationModel {
  final int orderIndex;
  final TripStationModel station;

  const TripRouteStationModel({
    required this.orderIndex,
    required this.station,
  });

  factory TripRouteStationModel.fromJson(Map<String, dynamic> json) {
    return TripRouteStationModel(
      orderIndex: json['orderIndex'] as int? ?? 0,
      station: TripStationModel.fromJson(
        json['station'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// Model trạm dừng (dùng trong Trip context).
class TripStationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const TripStationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory TripStationModel.fromJson(Map<String, dynamic> json) {
    return TripStationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
