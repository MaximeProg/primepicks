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
    final current = state.valueOrNull ?? [];
    state = AsyncData(current
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList());
    try {
      await ref.read(apiClientProvider).patch<dynamic>(
        '/notifications/inbox/$id/read',
      );
    } catch (_) {
      // Revert only if state is still valid; never blank the list on error
      final snapshot = state.valueOrNull;
      if (snapshot != null) {
        final refetched = await AsyncValue.guard(_fetch);
        // Only replace if the refetch returned data (not an error)
        if (refetched is AsyncData) state = refetched;
      }
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());
    try {
      await ref.read(apiClientProvider).post<dynamic>(
        '/notifications/inbox/read-all',
      );
    } catch (_) {
      final refetched = await AsyncValue.guard(_fetch);
      if (refetched is AsyncData) state = refetched;
    }
  }

  Future<void> delete(String id) async {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((n) => n.id != id).toList());
    try {
      await ref.read(apiClientProvider).delete('/notifications/inbox/$id');
    } catch (_) {
      final refetched = await AsyncValue.guard(_fetch);
      if (refetched is AsyncData) state = refetched;
    }
  }

  Future<void> clearAll() async {
    state = const AsyncData([]);
    try {
      await ref.read(apiClientProvider).delete('/notifications/inbox');
    } catch (_) {
      final refetched = await AsyncValue.guard(_fetch);
      if (refetched is AsyncData) state = refetched;
    }
  }

  int get unreadCount =>
      state.valueOrNull?.where((n) => !n.isRead).length ?? 0;
}
