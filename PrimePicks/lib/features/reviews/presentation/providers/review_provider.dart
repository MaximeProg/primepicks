import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/review_datasource.dart';
import '../../domain/entities/review_entity.dart';

final reviewDatasourceProvider = Provider<ReviewDatasource>(
  (ref) => ReviewDatasource(ref.watch(apiClientProvider)),
);

final reviewsProvider = FutureProvider<List<ReviewEntity>>((ref) async {
  return ref.watch(reviewDatasourceProvider).getApprovedReviews();
});

final reviewStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(reviewDatasourceProvider).getStats();
});
