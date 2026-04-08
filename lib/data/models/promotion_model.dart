/// Model chứa thông tin một mã khuyến mãi.
/// Parse từ response `GET /promotions/active`.
class PromotionModel {
  final String id;
  final String code;

  /// `PERCENTAGE` hoặc `FIXED`.
  final String discountType;

  /// Giá trị giảm (% hoặc số tiền cố định).
  final double discountValue;
  final int? usageLimit;
  final int usedCount;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;

  const PromotionModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.usageLimit,
    required this.usedCount,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      discountType: json['discountType'] as String? ?? 'PERCENTAGE',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      usageLimit: json['usageLimit'] as int?,
      usedCount: json['usedCount'] as int? ?? 0,
      validFrom: json['validFrom'] != null
          ? DateTime.parse(json['validFrom'] as String)
          : DateTime.now(),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Tính số tiền được giảm dựa trên giá gốc.
  double calculateDiscount(double originalPrice) {
    if (discountType == 'PERCENTAGE') {
      final discount = originalPrice * discountValue / 100;
      return discount > originalPrice ? originalPrice : discount;
    }
    // FIXED
    return discountValue > originalPrice ? originalPrice : discountValue;
  }

  /// Trả về chuỗi mô tả giảm giá (ví dụ: "Giảm 10%" hoặc "Giảm 50.000đ").
  String get discountLabel {
    if (discountType == 'PERCENTAGE') {
      return 'Giảm ${discountValue.toInt()}%';
    }
    return 'Giảm ${_formatCurrency(discountValue)}đ';
  }

  /// Số lượt sử dụng còn lại (null nếu không giới hạn).
  int? get remainingUsage =>
      usageLimit != null ? usageLimit! - usedCount : null;

  static String _formatCurrency(double amount) {
    // Format đơn giản: 50000 → 50.000
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
