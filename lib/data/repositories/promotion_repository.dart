import '../models/promotion_model.dart';

/// Interface (Abstract class) cho Promotion Repository.
/// Tất cả các tầng trên (Controller/Bloc) chỉ gọi qua interface này
/// để tuân thủ Dependency Inversion Principle.
abstract class PromotionRepository {
  /// Lấy danh sách mã khuyến mãi đang có hiệu lực.
  Future<List<PromotionModel>> getActivePromotions();
}
