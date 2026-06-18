import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/subscription_datasource.dart';
import '../../domain/entities/subscription_entity.dart';

final plansProvider = FutureProvider<List<PlanEntity>>((ref) async {
  return ref.watch(subscriptionDatasourceProvider).getPlans();
});

final mySubscriptionProvider = FutureProvider<SubscriptionEntity?>((ref) async {
  return ref.watch(subscriptionDatasourceProvider).getMySubscription();
});

final subscribeNotifierProvider =
    AsyncNotifierProvider<SubscribeNotifier, PaymentInitEntity?>(
  SubscribeNotifier.new,
);

class SubscribeNotifier extends AsyncNotifier<PaymentInitEntity?> {
  @override
  Future<PaymentInitEntity?> build() async => null;

  Future<PaymentInitEntity?> subscribe(String planId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionDatasourceProvider).subscribe(planId),
    );
    return state.valueOrNull;
  }
}
