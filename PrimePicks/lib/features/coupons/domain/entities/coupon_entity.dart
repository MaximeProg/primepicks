class MatchEntity {
  final String id;
  final String matchName;
  final String prediction;
  final double? odd;

  const MatchEntity({
    required this.id,
    required this.matchName,
    required this.prediction,
    this.odd,
  });
}

class CouponEntity {
  final String id;
  final String title;
  final String? description;
  final String? analysis;
  final double? odds;
  final String? bookmakerCode;
  final DateTime? validUntil;
  final String status;       // PENDING / WON / LOST / CANCELLED
  final String couponType;   // FREE / PREMIUM / VIP
  final int? confidenceLevel;
  final bool isPublished;
  final DateTime? publishedAt;
  final String? imageUrl;
  final DateTime createdAt;
  final List<MatchEntity> matches;

  const CouponEntity({
    required this.id,
    required this.title,
    this.description,
    this.analysis,
    this.odds,
    this.bookmakerCode,
    this.validUntil,
    required this.status,
    required this.couponType,
    this.confidenceLevel,
    required this.isPublished,
    this.publishedAt,
    this.imageUrl,
    required this.createdAt,
    this.matches = const [],
  });

  bool get isFree     => couponType == 'FREE';
  bool get isPremium  => couponType == 'PREMIUM';
  bool get isVip      => couponType == 'VIP';
  bool get isPending  => status == 'PENDING';
  bool get isWon      => status == 'WON';
  bool get isLost     => status == 'LOST';
}

class PublicStatsEntity {
  final int totalCoupons;
  final int won;
  final int lost;
  final int cancelled;
  final int pending;
  final double winRate;

  const PublicStatsEntity({
    required this.totalCoupons,
    required this.won,
    required this.lost,
    required this.cancelled,
    required this.pending,
    required this.winRate,
  });
}
