import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/coupon_datasource.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';

// Stats publiques
final publicStatsProvider = FutureProvider<PublicStatsEntity>((ref) async {
  return ref.watch(couponDatasourceProvider).getPublicStats();
});

// Coupons publics (accueil + non-abonnés)
final publicCouponsProvider = FutureProvider<List<CouponEntity>>((ref) async {
  return ref.watch(couponDatasourceProvider).getPublicCoupons(limit: 20);
});

// Coupons premium (abonnés)
final premiumCouponsProvider =
    AsyncNotifierProvider<PremiumCouponsNotifier, List<CouponEntity>>(
  PremiumCouponsNotifier.new,
);

class PremiumCouponsNotifier extends AsyncNotifier<List<CouponEntity>> {
  int _offset = 0;
  bool _hasMore = true;
  static const _limit = 20;

  @override
  Future<List<CouponEntity>> build() async {
    // Dépendance réactive : se recharge quand mySubscriptionProvider change
    // (abonnement activé, expiré, ou invalidé manuellement)
    final sub = ref.watch(mySubscriptionProvider);
    if (sub.valueOrNull?.isActive != true) return [];
    _offset = 0;
    _hasMore = true;
    return _fetch();
  }

  Future<List<CouponEntity>> _fetch() async {
    final ds = ref.read(couponDatasourceProvider);
    final items = await ds.getCoupons(limit: _limit, offset: _offset);
    if (items.length < _limit) _hasMore = false;
    _offset += items.length;
    return items;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    final more = await _fetch();
    state = AsyncData([...current, ...more]);
  }

  Future<void> refresh() async {
    _offset = 0;
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  bool get hasMore => _hasMore;
}

// Détail d'un coupon
final couponDetailProvider =
    FutureProvider.family<CouponEntity, String>((ref, id) async {
  return ref.watch(couponDatasourceProvider).getCoupon(id);
});
