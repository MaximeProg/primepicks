import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../services/fcm_service.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';
import '../../../coupons/presentation/providers/coupon_provider.dart';
import '../../../referral/presentation/providers/referral_provider.dart';

// Stream Firebase — sert de garde de navigation
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Profil utilisateur complet (depuis notre DB)
final userProfileProvider = StateProvider<UserEntity?>((ref) => null);

// Notifier principal auth
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<void> {
  /// Vide tout le cache utilisateur. À appeler avant chaque connexion/déconnexion
  /// pour qu'aucune donnée d'un ancien compte ne reste visible.
  void _clearUserData() {
    ref.read(userProfileProvider.notifier).state = null;
    ref.invalidate(mySubscriptionProvider);
    ref.invalidate(premiumCouponsProvider);
    ref.invalidate(referralInfoProvider);
    ref.invalidate(referralStatsProvider);
    ref.invalidate(plansProvider);
  }

  @override
  Future<void> build() async {
    Future<void> syncProfile(AsyncValue<User?> state) async {
      state.whenData((firebaseUser) async {
        if (firebaseUser == null) {
          // Ne PAS effacer ici : Firebase émet null transitoirement lors
          // d'un refresh token. Seul signOut() vide les données.
          return;
        }
        if (ref.read(userProfileProvider) == null) {
          try {
            final user = await ref.read(authRepositoryProvider).getCurrentUser();
            if (user != null) {
              ref.read(userProfileProvider.notifier).state = user;
            }
          } catch (_) {}
        }
        if (!kIsWeb) await ref.read(fcmServiceProvider).init();
      });
    }

    // Vérifier l'état actuel immédiatement (couvre le redémarrage de l'app)
    await syncProfile(ref.read(authStateProvider));
    // Écouter les changements futurs
    ref.listen(authStateProvider, (_, next) => syncProfile(next));
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    _clearUserData(); // Vider l'ancien compte avant de charger le nouveau
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      ref.read(userProfileProvider.notifier).state = user;
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    _clearUserData();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      ref.read(userProfileProvider.notifier).state = user;
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String? fullName,
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    _clearUserData();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        referralCode: referralCode,
      );
      ref.read(userProfileProvider.notifier).state = user;
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (!kIsWeb) await ref.read(fcmServiceProvider).deleteToken();
      await ref.read(authRepositoryProvider).signOut();
      _clearUserData(); // Vider toutes les données après déconnexion
    });
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    bool success = false;
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      success = true;
    });
    return success;
  }
}
