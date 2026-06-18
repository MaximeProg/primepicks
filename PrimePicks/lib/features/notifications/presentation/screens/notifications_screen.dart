import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../providers/notification_provider.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasUnread = (async.valueOrNull ?? []).any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (async.valueOrNull?.isNotEmpty == true) ...[
            if (hasUnread)
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllRead(),
                child: const Text(
                  'Tout lire',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            PopupMenuButton<_AppBarAction>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) => _onMenuAction(context, ref, action),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _AppBarAction.clearAll,
                  child: Row(children: [
                    Icon(Icons.delete_sweep_rounded, size: 18,
                        color: AppColors.error),
                    SizedBox(width: 10),
                    Text('Tout supprimer',
                        style: TextStyle(color: AppColors.error)),
                  ]),
                ),
              ],
            ),
          ],
        ],
      ),
      body: async.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, __) => const ShimmerBox.wide(height: 72, radius: 12),
        ),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(notificationsProvider.notifier).refresh(),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Aucune notification',
              subtitle:
                  'Vous serez notifié des nouvelles sélections et promotions.',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _NotificationTile(
                notif: list[i],
                isDark: isDark,
                onMarkRead: () =>
                    ref.read(notificationsProvider.notifier).markRead(list[i].id),
                onDelete: () =>
                    ref.read(notificationsProvider.notifier).delete(list[i].id),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onMenuAction(
      BuildContext context, WidgetRef ref, _AppBarAction action) {
    if (action == _AppBarAction.clearAll) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tout supprimer'),
          content: const Text(
              'Supprimer toutes les notifications ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(notificationsProvider.notifier).clearAll();
              },
              child: const Text('Supprimer',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
    }
  }
}

enum _AppBarAction { clearAll }

// ── Tile avec swipe ───────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notif;
  final bool isDark;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notif,
    required this.isDark,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: _SwipeBackground(isDark: isDark),
      confirmDismiss: (_) async {
        onDelete();
        return false; // on gère soi-même via le provider optimiste
      },
      child: GestureDetector(
        onTap: notif.isRead ? null : onMarkRead,
        child: _TileContent(notif: notif, isDark: isDark, onDelete: onDelete),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final bool isDark;
  const _SwipeBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_rounded, color: AppColors.error, size: 22),
    );
  }
}

class _TileContent extends StatelessWidget {
  final NotificationEntity notif;
  final bool isDark;
  final VoidCallback onDelete;
  const _TileContent({
    required this.notif,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notif.isRead;
    final type   = notif.type ?? 'INFO';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead
            ? (isDark ? AppColors.surfaceDark : AppColors.surface)
            : (isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? (isDark ? AppColors.borderDark : AppColors.border)
              : AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotifIcon(type: type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notif.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Fmt.relative(notif.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotifIcon extends StatelessWidget {
  final String type;
  const _NotifIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type.toUpperCase()) {
      'COUPON'         => (Icons.confirmation_number_rounded, AppColors.primary),
      'PAYMENT'        => (Icons.payment_rounded,             AppColors.success),
      'PROMO'          => (Icons.local_offer_rounded,         AppColors.accent),
      'SUB_ACTIVATED'  => (Icons.workspace_premium_rounded,   AppColors.primary),
      'TICKET_REPLIED' => (Icons.support_agent_rounded,       AppColors.accent),
      _                => (Icons.notifications_rounded,       AppColors.textSecondary),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
