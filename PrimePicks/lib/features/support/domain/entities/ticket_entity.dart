class TicketMessageEntity {
  final String id;
  final String ticketId;
  final String senderType; // USER | ADMIN
  final String? senderId;
  final String? content;
  final String? mediaUrl;
  final String? mediaType; // IMAGE | VIDEO | FILE
  final bool isRead;
  final DateTime createdAt;

  const TicketMessageEntity({
    required this.id,
    required this.ticketId,
    required this.senderType,
    this.senderId,
    this.content,
    this.mediaUrl,
    this.mediaType,
    required this.isRead,
    required this.createdAt,
  });

  bool get isFromUser => senderType == 'USER';
  bool get hasMedia => mediaUrl != null;
}

class TicketEntity {
  final String id;
  final String subject;
  final String status; // OPEN | IN_PROGRESS | CLOSED
  final List<TicketMessageEntity> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketEntity({
    required this.id,
    required this.subject,
    required this.status,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isClosed => status == 'CLOSED';
}

class TicketSummaryEntity {
  final String id;
  final String subject;
  final String status;
  final String? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketSummaryEntity({
    required this.id,
    required this.subject,
    required this.status,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });
}
