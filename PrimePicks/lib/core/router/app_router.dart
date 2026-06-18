import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/coupons/presentation/screens/coupon_detail_screen.dart';
import '../../features/coupons/presentation/screens/coupons_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/subscriptions/presentation/screens/subscriptions_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/referral/presentation/screens/referral_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/support/presentation/screens/ticket_chat_screen.dart';
import '../../shared/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.onboarding,
        AppRoutes.splash,
      ].contains(state.matchedLocation);

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute &&
          state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.splash,         builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding,     builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login,          builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register,       builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),

      // ── Plein écran (sans bottom nav) ────────────────────────────────────
      GoRoute(
        path: AppRoutes.couponDetail,
        builder: (_, state) =>
            CouponDetailScreen(couponId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.settings,   builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.support,    builder: (_, __) => const SupportScreen()),
      GoRoute(path: AppRoutes.ticketChat, builder: (_, s) =>
          TicketChatScreen(ticketId: s.pathParameters['ticketId']!)),
      GoRoute(path: AppRoutes.referral,   builder: (_, __) => const ReferralScreen()),
      GoRoute(path: AppRoutes.affiliate,  builder: (_, __) => const _SimpleScreen('Affiliation')),
      GoRoute(path: AppRoutes.payments,   builder: (_, __) => const PaymentsScreen()),
      GoRoute(path: AppRoutes.privacy,    builder: (_, __) => const _SimpleScreen('Confidentialité')),
      GoRoute(path: AppRoutes.terms,      builder: (_, __) => const _SimpleScreen('Conditions')),

      // ── Shell avec bottom nav ────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,          builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.coupons,        builder: (_, __) => const CouponsScreen()),
          GoRoute(path: AppRoutes.subscriptions,  builder: (_, __) => const SubscriptionsScreen()),
          GoRoute(path: AppRoutes.notifications,  builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: AppRoutes.profile,        builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

class AppRoutes {
  static const splash         = '/';
  static const onboarding     = '/onboarding';
  static const login          = '/login';
  static const register       = '/register';
  static const forgotPassword = '/forgot-password';
  static const home           = '/home';
  static const coupons        = '/coupons';
  static const couponDetail   = '/coupons/:id';
  static const subscriptions  = '/subscriptions';
  static const notifications  = '/notifications';
  static const profile        = '/profile';
  static const settings       = '/settings';
  static const support        = '/support';
  static const ticketChat     = '/support/:ticketId';
  static const referral       = '/referral';
  static const affiliate      = '/affiliate';
  static const payments       = '/payments';
  static const privacy        = '/privacy';
  static const terms          = '/terms';
}

class _SimpleScreen extends StatelessWidget {
  final String title;
  const _SimpleScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(À venir)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
