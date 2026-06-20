import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../services/fcm_service.dart';

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
  @override
  Future<void> build() async {
    // ref.listen ne déclenche pas de callback pour la valeur ACTUELLE —
    // il faut donc vérifier immédiatement + écouter les changements futurs.
    Future<void> syncProfile(AsyncValue<User?> state) async {
      state.whenData((firebaseUser) async {
        if (firebaseUser == null) {
          // Ne PAS effacer le profil ici : Firebase peut émettre null
          // transitoirement (refresh token, reprise en premier plan).
          // Seul signOut() doit effacer le profil explicitement.
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

    // 1. Vérifier l'état actuel immédiatement (couvre le redémarrage de l'app)
    await syncProfile(ref.read(authStateProvider));

    // 2. Écouter les changements futurs (connexion, déconnexion, refresh token)
    ref.listen(authStateProvider, (_, next) => syncProfile(next));
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmail(email, password);
      ref.read(userProfileProvider.notifier).state = user;
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithGoogle();
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
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signUpWithEmail(
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
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      ref.read(userProfileProvider.notifier).state = null;
    });
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    bool success = false;
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPasswordReset(email);
      success = true;
    });
    return success;
  }
}
