import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/promotion_model.dart';

/// Data source giao tiếp trực tiếp với backend cho luồng Promotion.
class PromotionApi {
  final DioClient _dioClient;

  PromotionApi(this._dioClient);

  /// Gọi API GET /promotions/active.
  /// Trả về danh sách mã khuyến mãi đang có hiệu lực.
  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final response = await _dioClient.dio.get(
        '/promotions/active',
        queryParameters: {'page': 1, 'limit': 50},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['data'] as Map<String, dynamic>? ?? {};
        final itemsList = result['data'] as List<dynamic>? ?? [];

        return itemsList
            .map((e) =>
                PromotionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Lấy danh sách khuyến mãi thất bại (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy danh sách khuyến mãi: $e');
    }
  }
}
