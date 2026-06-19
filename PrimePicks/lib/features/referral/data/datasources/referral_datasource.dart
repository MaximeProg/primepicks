import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/referral_entity.dart';

final referralDatasourceProvider = Provider((ref) =>
    ReferralDatasource(ref.read(apiClientProvider)));

class ReferralDatasource {
  final ApiClient _client;
  ReferralDatasource(this._client);

  Future<ReferralInfoEntity> getMyInfo() async {
    final j = await _client.get<Map<String, dynamic>>('/referrals/me');
    return ReferralInfoEntity(
      referralCode: j['referral_code'] as String,
      referralLink:  j['referral_link']  as String,
      totalReferred: j['total_referred'] as int,
      totalRewarded: j['total_rewarded'] as int,
    );
  }

  Future<List<ReferralEntryEntity>> getStats() async {
    final list = await _client.get<List<dynamic>>('/referrals/me/stats');
    return list.map((j) => ReferralEntryEntity(
      id:            j['id'] as String,
      referredName:  j['referred_name'] as String?,
      referredEmail: j['referred_email'] as String?,
      rewardGiven:   j['reward_given'] as bool,
      rewardedAt:    j['rewarded_at'] != null ? DateTime.parse(j['rewarded_at'] as String) : null,
      createdAt:     DateTime.parse(j['created_at'] as String),
    )).toList();
  }
}
