class ReferralInfoEntity {
  final String referralCode;
  final String referralLink;
  final int totalReferred;
  final int totalRewarded;

  const ReferralInfoEntity({
    required this.referralCode,
    required this.referralLink,
    required this.totalReferred,
    required this.totalRewarded,
  });
}

class ReferralEntryEntity {
  final String id;
  final String? referredName;
  final String? referredEmail;
  final bool rewardGiven;
  final DateTime? rewardedAt;
  final DateTime createdAt;

  const ReferralEntryEntity({
    required this.id,
    this.referredName,
    this.referredEmail,
    required this.rewardGiven,
    this.rewardedAt,
    required this.createdAt,
  });
}
