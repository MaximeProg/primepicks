import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../providers/referral_provider.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(title: const Text('Parrainage')),
      body: ref.watch(referralInfoProvider).when(
        loading: () => _Skeleton(isDark: isDark),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(referralInfoProvider),
        ),
        data: (info) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(referralInfoProvider);
            ref.invalidate(referralStatsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ReferralCodeCard(
                code: info.referralCode,
                link: info.referralLink,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _StatsRow(
                totalReferred: info.totalReferred,
                totalRewarded: info.totalRewarded,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _HowItWorks(isDark: isDark),
              const SizedBox(height: 24),
              Text(
                'Vos filleuls',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _ReferralList(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Code card ─────────────────────────────────────────────────────────────────

class _ReferralCodeCard extends StatelessWidget {
  final String code;
  final String link;
  final bool isDark;
  const _ReferralCodeCard({required this.code, required this.link, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Votre code parrain',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code copié'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Share.share(
                'Rejoignez PrimePicks avec mon code $code et accédez aux meilleures sélections sportives !\n$link',
                subject: 'Invitation PrimePicks',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Partager mon lien',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int totalReferred;
  final int totalRewarded;
  final bool isDark;
  const _StatsRow({
    required this.totalReferred,
    required this.totalRewarded,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Filleuls',
          value: '$totalReferred',
          icon: Icons.people_rounded,
          isDark: isDark,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Récompensés',
          value: '$totalRewarded',
          icon: Icons.workspace_premium_rounded,
          isDark: isDark,
          accent: true,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final bool accent;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.accent : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── How it works ──────────────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  final bool isDark;
  const _HowItWorks({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.share_rounded, 'Partagez votre code', 'Envoyez votre code à vos amis'),
      (Icons.person_add_rounded, 'Ils s\'inscrivent', 'Vos filleuls créent un compte'),
      (Icons.workspace_premium_rounded, 'Ils s\'abonnent', 'Dès leur 1er abonnement payant'),
      (Icons.card_giftcard_rounded, 'Vous gagnez', 'Des jours d\'abonnement offerts'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comment ça marche',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final idx = e.key;
            final (icon, title, sub) = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          sub,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Referral list ─────────────────────────────────────────────────────────────

class _ReferralList extends ConsumerWidget {
  final bool isDark;
  const _ReferralList({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(referralStatsProvider).when(
      loading: () => Column(
        children: List.generate(3, (_) =>
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: ShimmerBox.wide(height: 56, radius: 10),
            )),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'Aucun filleul pour l\'instant',
            subtitle: 'Partagez votre code pour commencer à gagner des récompenses.',
          );
        }
        return Column(
          children: entries.map((e) => _EntryTile(entry: e, isDark: isDark)).toList(),
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  final dynamic entry;
  final bool isDark;
  const _EntryTile({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (entry.rewardGiven
                  ? AppColors.success
                  : AppColors.textTertiary).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.rewardGiven
                  ? Icons.check_circle_rounded
                  : Icons.access_time_rounded,
              size: 18,
              color: entry.rewardGiven ? AppColors.success : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.rewardGiven ? 'Récompense obtenue' : 'En attente d\'abonnement',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  Fmt.date(entry.createdAt as DateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  final bool isDark;
  const _Skeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const ShimmerBox.wide(height: 180, radius: 16),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: ShimmerBox.wide(height: 80, radius: 12)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox.wide(height: 80, radius: 12)),
          ],
        ),
        const SizedBox(height: 24),
        const ShimmerBox.wide(height: 160, radius: 12),
      ],
    );
  }
}
