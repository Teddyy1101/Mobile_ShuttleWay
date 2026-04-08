/// Model chứa thông tin vé trong giao dịch.
class TransactionTicketModel {
  final String id;
  final String ticketType;
  final double priceAtBuy;
  final TransactionStudentModel? student;
  final TransactionRouteModel? route;

  const TransactionTicketModel({
    required this.id,
    required this.ticketType,
    required this.priceAtBuy,
    this.student,
    this.route,
  });

  factory TransactionTicketModel.fromJson(Map<String, dynamic> json) {
    return TransactionTicketModel(
      id: json['id'] as String? ?? '',
      ticketType: json['ticketType'] as String? ?? '',
      priceAtBuy: (json['priceAtBuy'] as num?)?.toDouble() ?? 0,
      student: json['student'] != null
          ? TransactionStudentModel.fromJson(
              json['student'] as Map<String, dynamic>)
          : null,
      route: json['route'] != null
          ? TransactionRouteModel.fromJson(
              json['route'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Model thông tin học sinh trong giao dịch.
class TransactionStudentModel {
  final String id;
  final String fullName;

  const TransactionStudentModel({
    required this.id,
    required this.fullName,
  });

  factory TransactionStudentModel.fromJson(Map<String, dynamic> json) {
    return TransactionStudentModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
    );
  }
}

/// Model thông tin người thanh toán trong giao dịch.
class TransactionUserModel {
  final String id;
  final String fullName;
  final String role;

  const TransactionUserModel({
    required this.id,
    required this.fullName,
    required this.role,
  });

  factory TransactionUserModel.fromJson(Map<String, dynamic> json) {
    return TransactionUserModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}

/// Model thông tin tuyến đường trong giao dịch.
class TransactionRouteModel {
  final String id;
  final String name;

  const TransactionRouteModel({
    required this.id,
    required this.name,
  });

  factory TransactionRouteModel.fromJson(Map<String, dynamic> json) {
    return TransactionRouteModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

/// Model chứa thông tin một giao dịch thanh toán.
/// Parse từ response `GET /transactions/my-transactions`.
class TransactionModel {
  final String id;
  final String transactionCode;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final TransactionTicketModel? ticket;
  final TransactionUserModel? user;

  const TransactionModel({
    required this.id,
    required this.transactionCode,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.ticket,
    this.user,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String? ?? '',
      transactionCode: json['transactionCode'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      ticket: json['ticket'] != null
          ? TransactionTicketModel.fromJson(
              json['ticket'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? TransactionUserModel.fromJson(
              json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Model response cho danh sách giao dịch (phân trang).
class TransactionListResponse {
  final List<TransactionModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const TransactionListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final result = data['data'] as Map<String, dynamic>? ?? {};
    final itemsList = result['data'] as List<dynamic>? ?? [];
    final meta = result['meta'] as Map<String, dynamic>? ?? {};

    return TransactionListResponse(
      items: itemsList
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int? ?? 0,
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 10,
      totalPages: meta['totalPages'] as int? ?? 0,
    );
  }
}
