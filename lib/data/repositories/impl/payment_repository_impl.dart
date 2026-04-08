import '../payment_repository.dart';
import '../../sources/transaction_api.dart';
import '../../models/transaction_model.dart';

/// Implement [PaymentRepository] sử dụng TransactionApi.
class ApiPaymentRepository implements PaymentRepository {
  final TransactionApi _transactionApi;

  ApiPaymentRepository(this._transactionApi);

  @override
  Future<TransactionModel> checkout({
    required String ticketId,
    required String paymentMethod,
    String? promotionCode,
  }) async {
    return _transactionApi.checkout(
      ticketId: ticketId,
      paymentMethod: paymentMethod,
      promotionCode: promotionCode,
    );
  }

  @override
  Future<String> getMoMoUrl(String transactionId) async {
    return _transactionApi.getMoMoUrl(transactionId);
  }

  @override
  Future<String> getVnPayUrl(String transactionId) async {
    return _transactionApi.getVnPayUrl(transactionId);
  }

  @override
  Future<String> checkTransactionStatus(String transactionId) async {
    return _transactionApi.checkTransactionStatus(transactionId);
  }
}
