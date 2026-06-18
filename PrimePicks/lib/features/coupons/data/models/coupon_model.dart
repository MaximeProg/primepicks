import '../../domain/entities/coupon_entity.dart';

class MatchModel extends MatchEntity {
  const MatchModel({
    required super.id,
    required super.matchName,
    required super.prediction,
    super.odd,
  });

  factory MatchModel.fromJson(Map<String, dynamic> j) => MatchModel(
        id: j['id'] as String,
        matchName: j['match_name'] as String,
        prediction: j['prediction'] as String,
        odd: (j['odd'] as num?)?.toDouble(),
      );
}

class CouponModel extends CouponEntity {
  const CouponModel({
    required super.id,
    required super.title,
    super.description,
    super.analysis,
    super.odds,
    super.bookmakerCode,
    super.validUntil,
    required super.status,
    required super.couponType,
    super.confidenceLevel,
    required super.isPublished,
    super.publishedAt,
    super.imageUrl,
    required super.createdAt,
    super.matches,
  });

  factory CouponModel.fromJson(Map<String, dynamic> j) => CouponModel(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        analysis: j['analysis'] as String?,
        odds: (j['odds'] as num?)?.toDouble(),
        bookmakerCode: j['bookmaker_code'] as String?,
        validUntil: j['valid_until'] != null
            ? DateTime.parse(j['valid_until'] as String)
            : null,
        status: j['status'] as String,
        couponType: j['coupon_type'] as String,
        confidenceLevel: j['confidence_level'] as int?,
        isPublished: j['is_published'] as bool? ?? false,
        publishedAt: j['published_at'] != null
            ? DateTime.parse(j['published_at'] as String)
            : null,
        imageUrl: j['image_url'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        matches: (j['matches'] as List<dynamic>?)
                ?.map((m) => MatchModel.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class PublicStatsModel extends PublicStatsEntity {
  const PublicStatsModel({
    required super.totalCoupons,
    required super.won,
    required super.lost,
    required super.cancelled,
    required super.pending,
    required super.winRate,
  });

  factory PublicStatsModel.fromJson(Map<String, dynamic> j) => PublicStatsModel(
        totalCoupons: j['total_coupons'] as int,
        won: j['won'] as int,
        lost: j['lost'] as int,
        cancelled: j['cancelled'] as int,
        pending: j['pending'] as int,
        winRate: (j['win_rate'] as num).toDouble(),
      );
}
