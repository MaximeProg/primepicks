import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/notification_entity.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationEntity>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<NotificationEntity>> {
  @override
  Future<List<NotificationEntity>> build() => _fetch();

  Future<List<NotificationEntity>> _fetch() async {
    final api = ref.read(apiClientProvider);
    final data = await api.get<List<dynamic>>('/notifications/inbox');
    return data
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  // Mise à jour locale optimiste puis confirmation API
  Future<void> markRead(String id) async {
    // Mise à jour optimiste
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList());
    }
    try {
      await ref.read(apiClientProvider).patch<void>(
        '/notifications/inbox/$id/read',
      );
    } catch (_) {
      // En cas d'erreur, on recharge
      state = await AsyncValue.guard(_fetch);
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());
    }
    try {
      await ref.read(apiClientProvider).post<void>(
        '/notifications/inbox/read-all',
      );
    } catch (_) {
      state = await AsyncValue.guard(_fetch);
    }
  }

  Future<void> delete(String id) async {
    // Suppression optimiste immédiate
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.where((n) => n.id != id).toList());
    }
    try {
      await ref.read(apiClientProvider).delete('/notifications/inbox/$id');
    } catch (_) {
      state = await AsyncValue.guard(_fetch);
    }
  }

  Future<void> clearAll() async {
    state = const AsyncData([]);
    try {
      await ref.read(apiClientProvider).delete('/notifications/inbox');
    } catch (_) {
      state = await AsyncValue.guard(_fetch);
    }
  }

  int get unreadCount =>
      state.valueOrNull?.where((n) => !n.isRead).length ?? 0;
}
