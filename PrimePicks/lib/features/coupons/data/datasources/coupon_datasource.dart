import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/coupon_model.dart';

final couponDatasourceProvider = Provider((ref) =>
    CouponDatasource(ref.watch(apiClientProvider)));

class CouponDatasource {
  final ApiClient _api;
  CouponDatasource(this._api);

  Future<List<CouponModel>> getPublicCoupons({int limit = 10}) async {
    final data = await _api.get<List<dynamic>>(
      '/coupons/public',
      queryParams: {'limit': limit},
    );
    return data.map((e) => CouponModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CouponModel>> getCoupons({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _api.get<List<dynamic>>(
      '/coupons',
      queryParams: {
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    return data.map((e) => CouponModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CouponModel> getCoupon(String id) async {
    final data = await _api.get<Map<String, dynamic>>('/coupons/$id');
    return CouponModel.fromJson(data);
  }

  Future<PublicStatsModel> getPublicStats() async {
    final data = await _api.get<Map<String, dynamic>>('/stats/public');
    return PublicStatsModel.fromJson(data);
  }
}
