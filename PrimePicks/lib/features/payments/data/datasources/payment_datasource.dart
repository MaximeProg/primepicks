import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/transaction_entity.dart';

final paymentDatasourceProvider = Provider((ref) =>
    PaymentDatasource(ref.read(apiClientProvider)));

class PaymentDatasource {
  final ApiClient _client;
  PaymentDatasource(this._client);

  Future<List<TransactionEntity>> getHistory({int limit = 50}) async {
    final list = await _client.get<List<dynamic>>(
      '/payments/history',
      queryParams: {'limit': limit},
    );
    return list.map(_fromJson).toList();
  }

  Future<TransactionEntity> verifyPayment(String transactionId) async {
    final j = await _client.post<Map<String, dynamic>>(
      '/payments/verify/$transactionId',
    );
    return _fromJson(j);
  }

  TransactionEntity _fromJson(dynamic j) => TransactionEntity(
    id:         j['id'] as String,
    planId:     j['plan_id'] as String?,
    amount:     (j['amount'] as num).toDouble(),
    currency:   j['currency'] as String,
    status:     j['status'] as String,
    paymentUrl: j['payment_url'] as String?,
    paidAt:     j['paid_at'] != null ? DateTime.parse(j['paid_at']) : null,
    createdAt:  DateTime.parse(j['created_at']),
  );
}
