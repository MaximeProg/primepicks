import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/ticket_entity.dart';

final supportDatasourceProvider = Provider((ref) =>
    SupportDatasource(ref.read(apiClientProvider)));

class SupportDatasource {
  final ApiClient _client;
  SupportDatasource(this._client);

  Future<List<TicketSummaryEntity>> getTickets() async {
    final list = await _client.get<List<dynamic>>('/support/tickets');
    return list.map(_summaryFromJson).toList();
  }

  Future<TicketEntity> getTicket(String ticketId) async {
    final j = await _client.get<Map<String, dynamic>>('/support/tickets/$ticketId');
    return _ticketFromJson(j);
  }

  Future<TicketEntity> createTicket(String subject, String message) async {
    final j = await _client.post<Map<String, dynamic>>(
      '/support/tickets',
      data: {'subject': subject, 'message': message},
    );
    return _ticketFromJson(j);
  }

  Future<TicketMessageEntity> sendMessage(
    String ticketId, {
    String? content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final j = await _client.post<Map<String, dynamic>>(
      '/support/tickets/$ticketId/messages',
      data: {
        if (content != null) 'content': content,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (mediaType != null) 'media_type': mediaType,
      },
    );
    return _messageFromJson(j);
  }

  TicketSummaryEntity _summaryFromJson(dynamic j) => TicketSummaryEntity(
    id:           j['id'] as String,
    subject:      j['subject'] as String,
    status:       j['status'] as String,
    lastMessage:  j['last_message'] as String?,
    unreadCount:  j['unread_count'] as int? ?? 0,
    createdAt:    DateTime.parse(j['created_at']),
    updatedAt:    DateTime.parse(j['updated_at']),
  );

  TicketEntity _ticketFromJson(dynamic j) => TicketEntity(
    id:        j['id'] as String,
    subject:   j['subject'] as String,
    status:    j['status'] as String,
    messages:  (j['messages'] as List? ?? []).map(_messageFromJson).toList(),
    createdAt: DateTime.parse(j['created_at']),
    updatedAt: DateTime.parse(j['updated_at']),
  );

  TicketMessageEntity _messageFromJson(dynamic j) => TicketMessageEntity(
    id:         j['id'] as String,
    ticketId:   j['ticket_id'] as String,
    senderType: j['sender_type'] as String,
    senderId:   j['sender_id'] as String?,
    content:    j['content'] as String?,
    mediaUrl:   j['media_url'] as String?,
    mediaType:  j['media_type'] as String?,
    isRead:     j['is_read'] as bool? ?? false,
    createdAt:  DateTime.parse(j['created_at']),
  );
}
