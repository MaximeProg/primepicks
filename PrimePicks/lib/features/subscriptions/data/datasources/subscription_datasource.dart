import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/subscription_model.dart';

final subscriptionDatasourceProvider = Provider(
    (ref) => SubscriptionDatasource(ref.watch(apiClientProvider)));

class SubscriptionDatasource {
  final ApiClient _api;
  SubscriptionDatasource(this._api);

  Future<List<PlanModel>> getPlans() async {
    final data = await _api.get<List<dynamic>>('/plans');
    return data
        .map((e) => PlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionModel?> getMySubscription() async {
    final data = await _api.get<dynamic>('/subscriptions/me');
    // Le backend retourne null (JSON null) quand pas d'abonnement
    if (data == null) return null;
    return SubscriptionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<PaymentInitModel> subscribe(String planId) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/subscriptions',
      data: {'plan_id': planId},
    );
    return PaymentInitModel.fromJson(data);
  }
}
