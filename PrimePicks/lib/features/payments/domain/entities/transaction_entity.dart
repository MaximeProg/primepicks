class TransactionEntity {
  final String id;
  final String? planId;
  final double amount;
  final String currency;
  final String status; // PENDING | PAID | FAILED | REFUNDED
  final String? paymentUrl;
  final DateTime? paidAt;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    this.planId,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentUrl,
    this.paidAt,
    required this.createdAt,
  });

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
  bool get isRefunded => status == 'REFUNDED';
}
