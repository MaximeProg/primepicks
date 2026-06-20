import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/subscriptions/presentation/providers/subscription_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(userProfileProvider);
    final subAsync = ref.watch(mySubscriptionProvider);
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── En-tête profil ──────────────────────────────────────────────
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                _AvatarWidget(
                  avatarUrl: user?.avatarUrl,
                  initials: user?.initials ?? '?',
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? '—',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.email ?? '—',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      subAsync.when(
                        loading: () => ShimmerBox(width: 100, height: 22, radius: 20),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (sub) => sub?.isActive == true
                            ? _PremiumBadge()
                            : _FreeBadge(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Points de fidélité + code parrainage ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.stars_rounded,
                    label: 'Points fidélité',
                    value: '${user?.loyaltyPoints ?? 0}',
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (user?.referralCode != null) {
                        Clipboard.setData(
                            ClipboardData(text: user?.referralCode ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copié dans le presse-papiers'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: _InfoCard(
                      icon: Icons.card_giftcard_rounded,
                      label: 'Code parrainage',
                      value: user?.referralCode ?? '—',
                      color: AppColors.primary,
                      copyable: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Abonnement actif ───────────────────────────────────────────
          subAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ShimmerBox.wide(height: 80, radius: 12),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (sub) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: sub != null && sub.isActive
                  ? _SubscriptionCard(
                      planName: sub.planName,
                      expiresAt: sub.expiresAt,
                    )
                  : _UpgradeBanner(
                      onTap: () => context.push(AppRoutes.subscriptions)),
            ),
          ),

          const SizedBox(height: 16),

          // ── Menu ───────────────────────────────────────────────────────
          _MenuSection(
            title: 'Mon compte',
            items: [
              _MenuItem(
                icon: Icons.workspace_premium_outlined,
                label: 'Mes abonnements',
                onTap: () => context.push(AppRoutes.subscriptions),
              ),
              _MenuItem(
                icon: Icons.people_outline_rounded,
                label: 'Parrainage',
                onTap: () => context.push(AppRoutes.referral),
              ),
              _MenuItem(
                icon: Icons.payment_outlined,
                label: 'Historique des paiements',
                onTap: () => context.push(AppRoutes.payments),
              ),
            ],
          ),

          _MenuSection(
            title: 'Communauté',
            items: [
              _MenuItem(
                icon: Icons.rate_review_outlined,
                label: 'Avis & Témoignages',
                onTap: () => context.push(AppRoutes.reviews),
              ),
            ],
          ),

          _MenuSection(
            title: 'Support',
            items: [
              _MenuItem(
                icon: Icons.support_agent_outlined,
                label: 'Contacter le support',
                onTap: () => context.push(AppRoutes.support),
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Politique de confidentialité',
                onTap: () => context.push(AppRoutes.privacy),
              ),
              _MenuItem(
                icon: Icons.article_outlined,
                label: 'Conditions d\'utilisation',
                onTap: () => context.push(AppRoutes.terms),
              ),
            ],
          ),

          _MenuSection(
            title: '',
            items: [
              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Se déconnecter',
                destructive: true,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => const _LogoutDialog(),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(authNotifierProvider.notifier).signOut();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  const _AvatarWidget({this.avatarUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySurface,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(initials),
              ),
            )
          : _Initials(initials),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  const _Initials(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Badges statut ──────────────────────────────────────────────────────────────

class _PremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _StatusBadge(
        label: 'Premium',
        color: AppColors.accent,
        surface: AppColors.accentSurface,
        icon: Icons.workspace_premium_rounded,
      );
}

class _FreeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _StatusBadge(
        label: 'Gratuit',
        color: AppColors.primary,
        surface: AppColors.primarySurface,
        icon: Icons.person_rounded,
      );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color surface;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.surface,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cartes info ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool copyable;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
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
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: copyable ? 1 : 0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (copyable)
                Icon(Icons.copy_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final String planName;
  final DateTime expiresAt;
  const _SubscriptionCard({required this.planName, required this.expiresAt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(planName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Expire le ${Fmt.date(expiresAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Actif',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Passer au Premium pour accéder à tous les coupons',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Menu sections ──────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            child: Column(
              children: items
                  .asMap()
                  .entries
                  .map((e) => Column(
                        children: [
                          e.value,
                          if (e.key < items.length - 1)
                            Divider(
                              height: 1,
                              indent: 52,
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                            ),
                        ],
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : null;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: destructive
          ? null
          : Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textTertiary,
            ),
    );
  }
}

// ── Dialog déconnexion ─────────────────────────────────────────────────────────

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Se déconnecter'),
      content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre compte ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Déconnecter'),
        ),
      ],
    );
  }
}
