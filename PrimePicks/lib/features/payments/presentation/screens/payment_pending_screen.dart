import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/data/datasources/payment_datasource.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';

class PaymentPendingScreen extends ConsumerStatefulWidget {
  final String transactionId;
  final String paymentUrl;

  const PaymentPendingScreen({
    super.key,
    required this.transactionId,
    required this.paymentUrl,
  });

  @override
  ConsumerState<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends ConsumerState<PaymentPendingScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _verifying = false;
  bool _paid = false;
  String? _error;

  // URL de callback FedaPay — quand FedaPay redirige ici, le paiement est terminé
  static const _callbackBase = 'primepicks-kappa.vercel.app/payment/callback';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (error) {
          if (mounted) setState(() { _loading = false; _error = 'Erreur de chargement'; });
        },
        onNavigationRequest: (request) {
          // FedaPay redirige vers callback_url après paiement (succès OU échec)
          if (request.url.contains(_callbackBase)) {
            _onPaymentComplete();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _onPaymentComplete() async {
    if (_verifying || _paid) return;
    setState(() { _verifying = true; _error = null; _loading = false; });
    try {
      final txn = await ref.read(paymentDatasourceProvider).verifyPayment(widget.transactionId);
      if (!mounted) return;
      if (txn.isPaid) {
        setState(() { _paid = true; _verifying = false; });
        ref.invalidate(mySubscriptionProvider);
        await _showSuccess();
      } else {
        setState(() {
          _verifying = false;
          _error = txn.isFailed ? 'Paiement refusé.' : 'Paiement non confirmé.';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _verifying = false; _error = 'Erreur de vérification.'; });
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
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            SizedBox(height: 16),
            Text(
              'Paiement confirmé !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
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
        title: const Text('Paiement sécurisé'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(AppRoutes.subscriptions),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // WebView principal
          if (!_verifying && !_paid && _error == null)
            WebViewWidget(controller: _controller),

          // Écran de vérification après retour de FedaPay
          if (_verifying)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Vérification du paiement…', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    'Nous confirmons votre paiement avec FedaPay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Écran d'erreur
          if (_error != null && !_verifying)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _onPaymentComplete,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Vérifier à nouveau'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.subscriptions),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
