/// Model thông tin học sinh trong vé.
class TicketStudentModel {
  final String id;
  final String fullName;
  final String? email;
  final String? avatarUrl;

  const TicketStudentModel({
    required this.id,
    required this.fullName,
    this.email,
    this.avatarUrl,
  });

  factory TicketStudentModel.fromJson(Map<String, dynamic> json) {
    return TicketStudentModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

/// Model thông tin phụ huynh trong vé.
class TicketParentModel {
  final String id;
  final String fullName;
  final String? email;

  const TicketParentModel({
    required this.id,
    required this.fullName,
    this.email,
  });

  factory TicketParentModel.fromJson(Map<String, dynamic> json) {
    return TicketParentModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
    );
  }
}

/// Model thông tin tuyến đường trong vé.
class TicketRouteModel {
  final String id;
  final String name;
  final String? shiftType;
  final double? singlePrice;
  final double? monthlyPrice;

  const TicketRouteModel({
    required this.id,
    required this.name,
    this.shiftType,
    this.singlePrice,
    this.monthlyPrice,
  });

  factory TicketRouteModel.fromJson(Map<String, dynamic> json) {
    return TicketRouteModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shiftType: json['shiftType'] as String?,
      singlePrice: (json['singlePrice'] as num?)?.toDouble(),
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble(),
    );
  }
}

/// Model chứa thông tin một vé xe.
/// Parse từ response `GET /tickets/my-tickets`.
class TicketModel {
  final String id;
  final String ticketType;
  final String status;
  final double priceAtBuy;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime createdAt;
  final TicketStudentModel? student;
  final TicketParentModel? parent;
  final TicketRouteModel? route;

  const TicketModel({
    required this.id,
    required this.ticketType,
    required this.status,
    required this.priceAtBuy,
    required this.validFrom,
    required this.validUntil,
    required this.createdAt,
    this.student,
    this.parent,
    this.route,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String? ?? '',
      ticketType: json['ticketType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      priceAtBuy: (json['priceAtBuy'] as num?)?.toDouble() ?? 0,
      validFrom: json['validFrom'] != null
          ? DateTime.parse(json['validFrom'] as String)
          : DateTime.now(),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      student: json['student'] != null
          ? TicketStudentModel.fromJson(
              json['student'] as Map<String, dynamic>)
          : null,
      parent: json['parent'] != null
          ? TicketParentModel.fromJson(
              json['parent'] as Map<String, dynamic>)
          : null,
      route: json['route'] != null
          ? TicketRouteModel.fromJson(
              json['route'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Model response cho danh sách vé (phân trang).
class TicketListResponse {
  final List<TicketModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const TicketListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}
