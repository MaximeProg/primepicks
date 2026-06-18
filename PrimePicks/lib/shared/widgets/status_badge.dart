import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum CouponStatus { pending, won, lost, cancelled }
enum CouponType   { free, premium, vip }

extension CouponStatusX on CouponStatus {
  String get label => switch (this) {
    CouponStatus.pending   => 'En cours',
    CouponStatus.won       => 'Gagné',
    CouponStatus.lost      => 'Perdu',
    CouponStatus.cancelled => 'Annulé',
  };

  Color get color => switch (this) {
    CouponStatus.pending   => AppColors.primary,
    CouponStatus.won       => AppColors.success,
    CouponStatus.lost      => AppColors.error,
    CouponStatus.cancelled => AppColors.textTertiary,
  };

  Color get surfaceColor => switch (this) {
    CouponStatus.pending   => AppColors.primarySurface,
    CouponStatus.won       => AppColors.successSurface,
    CouponStatus.lost      => AppColors.errorSurface,
    CouponStatus.cancelled => AppColors.surfaceVariant,
  };

  IconData get icon => switch (this) {
    CouponStatus.pending   => Icons.schedule_rounded,
    CouponStatus.won       => Icons.check_circle_rounded,
    CouponStatus.lost      => Icons.cancel_rounded,
    CouponStatus.cancelled => Icons.block_rounded,
  };

  static CouponStatus fromString(String s) => switch (s.toUpperCase()) {
    'WON'       => CouponStatus.won,
    'LOST'      => CouponStatus.lost,
    'CANCELLED' => CouponStatus.cancelled,
    _           => CouponStatus.pending,
  };
}

extension CouponTypeX on CouponType {
  String get label => switch (this) {
    CouponType.free    => 'Gratuit',
    CouponType.premium => 'Premium',
    CouponType.vip     => 'VIP',
  };

  Color get color => switch (this) {
    CouponType.free    => AppColors.primary,
    CouponType.premium => AppColors.accent,
    CouponType.vip     => const Color(0xFF7C3AED),
  };

  Color get surfaceColor => switch (this) {
    CouponType.free    => AppColors.primarySurface,
    CouponType.premium => AppColors.accentSurface,
    CouponType.vip     => const Color(0xFFF5F3FF),
  };

  static CouponType fromString(String s) => switch (s.toUpperCase()) {
    'PREMIUM' => CouponType.premium,
    'VIP'     => CouponType.vip,
    _         => CouponType.free,
  };
}

class StatusBadge extends StatelessWidget {
  final CouponStatus status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return _Badge(
      label: status.label,
      color: status.color,
      surface: status.surfaceColor,
      icon: status.icon,
    );
  }
}

class TypeBadge extends StatelessWidget {
  final CouponType type;
  const TypeBadge(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    return _Badge(
      label: type.label,
      color: type.color,
      surface: type.surfaceColor,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color surface;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.surface,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Barre de confiance
class ConfidenceBar extends StatelessWidget {
  final int level; // 1-5
  const ConfidenceBar(this.level, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < level;
        return Container(
          margin: const EdgeInsets.only(right: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.accent : AppColors.border,
          ),
        );
      }),
    );
  }
}
