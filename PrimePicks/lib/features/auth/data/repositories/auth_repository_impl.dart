import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return AuthRepositoryImpl(
    AuthRemoteDatasource(FirebaseAuth.instance, dio),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  AuthRepositoryImpl(this._remote);

  @override
  Future<UserEntity> signInWithEmail(String email, String password) =>
      _remote.signInWithEmail(email, password);

  @override
  Future<UserEntity> signInWithGoogle() => _remote.signInWithGoogle();

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String? fullName,
    String? referralCode,
  }) =>
      _remote.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        referralCode: referralCode,
      );

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _remote.sendPasswordReset(email);

  @override
  Future<UserEntity?> getCurrentUser() => _remote.getCurrentUser();
}
