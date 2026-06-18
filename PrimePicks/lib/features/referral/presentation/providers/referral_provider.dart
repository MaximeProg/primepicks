import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/referral_datasource.dart';
import '../../domain/entities/referral_entity.dart';

final referralInfoProvider = FutureProvider<ReferralInfoEntity>((ref) =>
    ref.read(referralDatasourceProvider).getMyInfo());

final referralStatsProvider = FutureProvider<List<ReferralEntryEntity>>((ref) =>
    ref.read(referralDatasourceProvider).getStats());
