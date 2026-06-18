import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithEmail(String email, String password);
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String? fullName,
    String? referralCode,
  });
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<UserEntity?> getCurrentUser();
}
