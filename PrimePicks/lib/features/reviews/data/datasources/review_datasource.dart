import '../../../../core/network/api_client.dart';
import '../../domain/entities/review_entity.dart';

class ReviewDatasource {
  const ReviewDatasource(this._api);
  final ApiClient _api;

  Future<List<ReviewEntity>> getApprovedReviews() async {
    final data = await _api.get<List<dynamic>>('/reviews');
    return data
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    return await _api.get<Map<String, dynamic>>('/reviews/stats');
  }

  Future<void> submitReview({required int rating, String? comment}) async {
    await _api.post<dynamic>(
      '/reviews',
      data: {'rating': rating, if (comment != null && comment.isNotEmpty) 'comment': comment},
    );
  }

  static ReviewEntity _fromJson(Map<String, dynamic> j) => ReviewEntity(
        id:         j['id'] as String,
        rating:     j['rating'] as int,
        comment:    j['comment'] as String?,
        authorName: j['author_name'] as String?,
        createdAt:  DateTime.parse(j['created_at'] as String),
      );
}
