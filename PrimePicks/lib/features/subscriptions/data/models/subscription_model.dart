import '../../domain/entities/subscription_entity.dart';

class PlanModel extends PlanEntity {
  const PlanModel({
    required super.id,
    required super.name,
    super.description,
    required super.price,
    required super.currency,
    required super.durationDays,
    required super.isActive,
    super.features,
  });

  factory PlanModel.fromJson(Map<String, dynamic> j) => PlanModel(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        price: (j['price'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'XOF',
        durationDays: j['duration_days'] as int,
        isActive: j['is_active'] as bool? ?? true,
        features: _parseFeatures(j['features']),
      );

  static List<String> _parseFeatures(dynamic f) {
    if (f == null) return [];
    if (f is List) return f.map((e) => e.toString()).toList();
    if (f is Map) {
      // Backend stocke {"coupons": true, "analyses": true} → labels lisibles
      return f.entries
          .where((e) => e.value == true)
          .map((e) => _label(e.key.toString()))
          .toList();
    }
    return [];
  }

  static String _label(String key) => switch (key) {
        'coupons'       => 'Coupons illimités',
        'analyses'      => 'Analyses détaillées',
        'notifications' => 'Notifications en temps réel',
        'stats'         => 'Statistiques avancées',
        'priority'      => 'Support prioritaire',
        'vip'           => 'Accès VIP',
        _               => key,
      };
}

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.id,
    required super.userId,
    required super.planId,
    required super.planName,
    required super.status,
    required super.startDate,
    required super.endDate,
    required super.amountPaid,
    required super.currency,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> j) =>
      SubscriptionModel(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        planId: j['plan_id'] as String,
        planName: j['plan_name'] as String? ?? '',
        status: j['status'] as String,
        startDate: DateTime.parse(j['start_date'] as String),
        endDate: DateTime.parse(j['end_date'] as String),
        amountPaid: (j['amount_paid'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'XOF',
      );
}

class PaymentInitModel extends PaymentInitEntity {
  const PaymentInitModel({
    required super.transactionId,
    required super.paymentUrl,
    required super.amount,
    required super.currency,
  });

  factory PaymentInitModel.fromJson(Map<String, dynamic> j) => PaymentInitModel(
        transactionId: j['transaction_id'] as String,
        paymentUrl: j['payment_url'] as String,
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'XOF',
      );
}
