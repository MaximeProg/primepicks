import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/entities/coupon_entity.dart';

class CouponCard extends StatelessWidget {
  final CouponEntity coupon;
  final bool locked; // non-abonné sur contenu premium

  const CouponCard({super.key, required this.coupon, this.locked = false});

  @override
  Widget build(BuildContext context) {
    final status = CouponStatusX.fromString(coupon.status);
    final type   = CouponTypeX.fromString(coupon.couponType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: locked ? null : () => context.push('/coupons/${coupon.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Stack(
          children: [
            // Barre latérale colorée selon le statut
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: status.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      TypeBadge(type),
                      const Spacer(),
                      StatusBadge(status),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Titre
                  Text(
                    coupon.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),

                  if (coupon.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      coupon.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Infos bas
                  Row(
                    children: [
                      if (coupon.odds != null) ...[
                        _InfoChip(
                          icon: Icons.trending_up_rounded,
                          label: 'Cote ${Fmt.odds(coupon.odds)}',
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (coupon.matches.isNotEmpty)
                        _InfoChip(
                          icon: Icons.sports_soccer_rounded,
                          label: '${coupon.matches.length} match${coupon.matches.length > 1 ? 's' : ''}',
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      if (coupon.confidenceLevel != null) ...[
                        const SizedBox(width: 10),
                        ConfidenceBar(coupon.confidenceLevel!),
                      ],
                      const Spacer(),
                      Text(
                        Fmt.relative(coupon.publishedAt ?? coupon.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Overlay verrou si premium non abonné
            if (locked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.backgroundDark : Colors.white)
                        .withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentSurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded,
                              color: AppColors.accent, size: 22),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Abonnement requis',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
