class PlanEntity {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final int durationDays;
  final bool isActive;
  final List<String> features;

  const PlanEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.isActive,
    this.features = const [],
  });
}

class SubscriptionEntity {
  final String id;
  final String userId;
  final String planId;
  final String planName;
  final String status; // ACTIVE / EXPIRED / CANCELLED
  final DateTime startDate;
  final DateTime endDate;
  final double amountPaid;
  final String currency;

  const SubscriptionEntity({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.amountPaid,
    required this.currency,
  });

  bool get isActive  => status == 'ACTIVE';
  bool get isExpired => status == 'EXPIRED';

  DateTime get expiresAt => endDate;
}

class PaymentInitEntity {
  final String transactionId;
  final String paymentUrl;
  final double amount;
  final String currency;

  const PaymentInitEntity({
    required this.transactionId,
    required this.paymentUrl,
    required this.amount,
    required this.currency,
  });
}
