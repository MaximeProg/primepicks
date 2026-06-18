import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/coupon_provider.dart';

class CouponDetailScreen extends ConsumerWidget {
  final String couponId;
  const CouponDetailScreen({super.key, required this.couponId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(couponDetailProvider(couponId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: async.when(
        loading: () => const _DetailShimmer(),
        error: (e, _) => _DetailError(
          message: e.toString(),
          onRetry: () => ref.invalidate(couponDetailProvider(couponId)),
        ),
        data: (coupon) {
          final status = CouponStatusX.fromString(coupon.status);
          final type   = CouponTypeX.fromString(coupon.couponType);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                pinned: true,
                title: const Text('Détail du coupon'),
                backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                elevation: 0,
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Badges ────────────────────────────────────────────
                      Row(
                        children: [
                          TypeBadge(type),
                          const SizedBox(width: 8),
                          StatusBadge(status),
                          const Spacer(),
                          if (coupon.confidenceLevel != null)
                            ConfidenceBar(coupon.confidenceLevel!),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Titre ─────────────────────────────────────────────
                      Text(
                        coupon.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),

                      if (coupon.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          coupon.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── Méta-infos ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.border,
                          ),
                        ),
                        child: Column(
                          children: [
                            _MetaRow(
                              icon: Icons.trending_up_rounded,
                              label: 'Cote globale',
                              value: Fmt.odds(coupon.odds),
                              valueColor: AppColors.accent,
                            ),
                            if (coupon.bookmakerCode != null) ...[
                              const Divider(height: 20),
                              _MetaRow(
                                icon: Icons.tag_rounded,
                                label: 'Code bookmaker',
                                value: coupon.bookmakerCode!,
                                monospace: true,
                              ),
                            ],
                            if (coupon.validUntil != null) ...[
                              const Divider(height: 20),
                              _MetaRow(
                                icon: Icons.schedule_rounded,
                                label: 'Valide jusqu\'au',
                                value: Fmt.dateTime(coupon.validUntil),
                              ),
                            ],
                            const Divider(height: 20),
                            _MetaRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'Publié le',
                              value: Fmt.dateTime(coupon.publishedAt ?? coupon.createdAt),
                            ),
                          ],
                        ),
                      ),

                      // ── Matches ───────────────────────────────────────────
                      if (coupon.matches.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Matches inclus',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...coupon.matches.map(
                          (m) => _MatchTile(match: m, isDark: isDark),
                        ),
                      ],

                      // ── Analyse ───────────────────────────────────────────
                      if (coupon.analysis != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Analyse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primarySurfaceDark
                                : AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(
                                  alpha: isDark ? 0.3 : 0.2),
                            ),
                          ),
                          child: Text(
                            coupon.analysis!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool monospace;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ??
                (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
            fontFamily: monospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  final dynamic match;
  final bool isDark;
  const _MatchTile({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_soccer_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.matchName as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  match.prediction as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (match.odd != null)
            Text(
              Fmt.odds(match.odd as double?),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }
}

// ── États loading / error ──────────────────────────────────────────────────────

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Détail du coupon'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surface,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(children: [
                ShimmerBox(width: 70, height: 24, radius: 6),
                const SizedBox(width: 8),
                ShimmerBox(width: 70, height: 24, radius: 6),
              ]),
              const SizedBox(height: 16),
              const ShimmerBox.wide(height: 28, radius: 4),
              const SizedBox(height: 8),
              const ShimmerBox.wide(height: 18, radius: 4),
              const SizedBox(height: 20),
              const ShimmerBox.wide(height: 120, radius: 12),
              const SizedBox(height: 24),
              const ShimmerBox.wide(height: 200, radius: 12),
            ]),
          ),
        ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _DetailError({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('Erreur de chargement',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
