import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../../../../services/preferences_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final user = ref.read(authStateProvider).valueOrNull;
    final prefs = ref.read(prefsProvider);
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (user != null) {
      context.go(AppRoutes.home);
    } else if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond football
          Image.network(
            'https://plus.unsplash.com/premium_photo-1661881970542-8447015772e8?q=80&w=687&auto=format&fit=crop',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D2137)),
          ),

          // Overlay sombre pour lisibilité
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0xCC001428),
                ],
              ),
            ),
          ),

          // Contenu centré
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / icône
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'PrimePicks',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Coupons Premium',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 56),

                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white.withValues(alpha: 0.7),
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
