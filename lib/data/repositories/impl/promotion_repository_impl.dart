import '../promotion_repository.dart';
import '../../sources/promotion_api.dart';
import '../../models/promotion_model.dart';

/// Implement [PromotionRepository] sử dụng PromotionApi.
class ApiPromotionRepository implements PromotionRepository {
  final PromotionApi _promotionApi;

  ApiPromotionRepository(this._promotionApi);

  @override
  Future<List<PromotionModel>> getActivePromotions() async {
    return _promotionApi.getActivePromotions();
  }
}
