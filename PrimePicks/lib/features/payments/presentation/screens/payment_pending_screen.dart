import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/data/datasources/payment_datasource.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';

class PaymentPendingScreen extends ConsumerStatefulWidget {
  final String transactionId;
  const PaymentPendingScreen({super.key, required this.transactionId});

  @override
  ConsumerState<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends ConsumerState<PaymentPendingScreen>
    with WidgetsBindingObserver {
  bool _verifying = false;
  bool _paid = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Dès que l'utilisateur revient dans l'app depuis le navigateur, on vérifie
    if (state == AppLifecycleState.resumed && !_paid) {
      _verify();
    }
  }

  Future<void> _verify() async {
    if (_verifying || _paid) return;
    setState(() { _verifying = true; _error = null; });
    try {
      final txn = await ref.read(paymentDatasourceProvider).verifyPayment(widget.transactionId);
      if (!mounted) return;
      if (txn.isPaid) {
        setState(() { _paid = true; _verifying = false; });
        // Rafraîchir l'abonnement affiché partout dans l'app
        ref.invalidate(mySubscriptionProvider);
        await _showSuccess();
      } else {
        setState(() {
          _verifying = false;
          _error = txn.isFailed
              ? 'Paiement refusé. Veuillez réessayer.'
              : 'Paiement non encore confirmé.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _verifying = false; _error = 'Erreur de vérification. Réessayez.'; });
    }
  }

  Future<void> _showSuccess() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Paiement confirmé !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre abonnement est maintenant actif.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.subscriptions);
              },
              child: const Text('Accéder à mes coupons'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Vérification du paiement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.subscriptions),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_verifying) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Vérification en cours…',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nous interrogeons FedaPay pour confirmer votre paiement.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (_paid) ...[
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
              const SizedBox(height: 16),
              const Text('Paiement confirmé !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ] else ...[
              Icon(
                _error != null ? Icons.pending_outlined : Icons.hourglass_empty_rounded,
                size: 64,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                _error ?? 'En attente de votre paiement',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Terminez le paiement dans le navigateur,\npuis revenez ici.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _verify,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("J'ai payé — Vérifier mon abonnement"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.subscriptions),
                child: const Text('Annuler'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
