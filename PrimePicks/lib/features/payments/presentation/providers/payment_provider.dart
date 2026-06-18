import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/payment_datasource.dart';
import '../../domain/entities/transaction_entity.dart';

final paymentHistoryProvider = FutureProvider<List<TransactionEntity>>((ref) =>
    ref.read(paymentDatasourceProvider).getHistory());
