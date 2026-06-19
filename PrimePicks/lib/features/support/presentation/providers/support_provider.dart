import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/support_datasource.dart';
import '../../domain/entities/ticket_entity.dart';

// ── Tickets list ──────────────────────────────────────────────────────────────

final ticketsProvider = FutureProvider<List<TicketSummaryEntity>>((ref) =>
    ref.read(supportDatasourceProvider).getTickets());

// ── Chat notifier (family: ticketId) ─────────────────────────────────────────

class TicketChatNotifier extends FamilyAsyncNotifier<TicketEntity, String> {
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _pollTimer;

  @override
  Future<TicketEntity> build(String arg) async {
    final ticket = await ref.read(supportDatasourceProvider).getTicket(arg);

    ref.onDispose(() {
      _channel?.sink.close();
      _pingTimer?.cancel();
      _pollTimer?.cancel();
    });

    _connectWs(arg);
    return ticket;
  }

  // ── WebSocket ───────────────────────────────────────────────────────────────

  void _connectWs(String ticketId) {
    _channel?.sink.close();
    _pingTimer?.cancel();
    _pollTimer?.cancel();

    final wsBase = AppConstants.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$wsBase/support/tickets/$ticketId/ws');

    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (raw) => _onWsMessage(raw as String),
        onDone: () => Future.delayed(const Duration(seconds: 3), () => _connectWs(ticketId)),
        onError: (_) => _startPolling(),
      );
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        try { _channel?.sink.add('ping'); } catch (_) {}
      });
    } catch (_) {
      _startPolling();
    }
  }

  void _onWsMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['type'] != 'new_message') return;
      final msgJson = data['message'] as Map<String, dynamic>;
      final msg = _parseMessage(msgJson);
      _appendMessage(msg);
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _silentRefresh());
  }

  Future<void> _silentRefresh() async {
    try {
      final ticket = await ref.read(supportDatasourceProvider).getTicket(arg);
      state = AsyncData(ticket);
    } catch (_) {}
  }

  void _appendMessage(TicketMessageEntity msg) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.messages.any((m) => m.id == msg.id)) return;
    state = AsyncData(TicketEntity(
      id: current.id, subject: current.subject, status: current.status,
      messages: [...current.messages, msg],
      createdAt: current.createdAt, updatedAt: current.updatedAt,
    ));
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> sendText(String content) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic
    final tmp = _optimisticMsg(content: content);
    state = AsyncData(_withMsg(current, tmp));

    try {
      final sent = await ref
          .read(supportDatasourceProvider)
          .sendMessage(arg, content: content);
      final updated = state.valueOrNull;
      if (updated == null) return;
      // WS may have already added the real message before this resolves
      final alreadyAdded = updated.messages.any((m) => m.id == sent.id);
      final msgs = updated.messages.where((m) => m.id != tmp.id).toList();
      if (!alreadyAdded) msgs.add(sent);
      state = AsyncData(_withMsgs(updated, msgs));
    } catch (e) {
      final updated = state.valueOrNull;
      if (updated == null) return;
      state = AsyncData(_withMsgs(
        updated, updated.messages.where((m) => m.id != tmp.id).toList(),
      ));
      rethrow;
    }
  }

  Future<void> sendMedia(String mediaUrl, String mediaType) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final tmp = _optimisticMsg(mediaUrl: mediaUrl, mediaType: mediaType);
    state = AsyncData(_withMsg(current, tmp));

    try {
      final sent = await ref.read(supportDatasourceProvider).sendMessage(
        arg, mediaUrl: mediaUrl, mediaType: mediaType,
      );
      final updated = state.valueOrNull;
      if (updated == null) return;
      final alreadyAdded = updated.messages.any((m) => m.id == sent.id);
      final msgs = updated.messages.where((m) => m.id != tmp.id).toList();
      if (!alreadyAdded) msgs.add(sent);
      state = AsyncData(_withMsgs(updated, msgs));
    } catch (e) {
      final updated = state.valueOrNull;
      if (updated == null) return;
      state = AsyncData(_withMsgs(
        updated, updated.messages.where((m) => m.id != tmp.id).toList(),
      ));
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(supportDatasourceProvider).getTicket(arg));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  TicketMessageEntity _optimisticMsg({String? content, String? mediaUrl, String? mediaType}) => TicketMessageEntity(
    id:         'tmp-${DateTime.now().millisecondsSinceEpoch}',
    ticketId:   arg,
    senderType: 'USER',
    content:    content,
    mediaUrl:   mediaUrl,
    mediaType:  mediaType,
    isRead:     false,
    createdAt:  DateTime.now(),
  );

  TicketEntity _withMsg(TicketEntity t, TicketMessageEntity m) =>
      _withMsgs(t, [...t.messages, m]);

  TicketEntity _withMsgs(TicketEntity t, List<TicketMessageEntity> msgs) =>
      TicketEntity(id: t.id, subject: t.subject, status: t.status,
          messages: msgs, createdAt: t.createdAt, updatedAt: t.updatedAt);

  TicketMessageEntity _parseMessage(Map<String, dynamic> j) => TicketMessageEntity(
    id:         j['id'] as String,
    ticketId:   j['ticket_id'] as String,
    senderType: j['sender_type'] as String,
    senderId:   j['sender_id'] as String?,
    content:    j['content'] as String?,
    mediaUrl:   j['media_url'] as String?,
    mediaType:  j['media_type'] as String?,
    isRead:     j['is_read'] as bool? ?? false,
    createdAt:  DateTime.parse(j['created_at'] as String),
  );
}

final ticketChatProvider =
    AsyncNotifierProvider.family<TicketChatNotifier, TicketEntity, String>(
  TicketChatNotifier.new,
);
