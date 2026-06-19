import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final FirebaseAuth _auth;
  final Dio _dio;


  AuthRemoteDatasource(this._auth, this._dio);

  // Sync l'utilisateur Firebase vers notre DB et retourne le profil complet
  Future<UserModel> _syncUser(
    User firebaseUser, {
    String? fullName,
    String? referralCode,
  }) async {
    final token = await firebaseUser.getIdToken();
    final body = <String, dynamic>{
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
    };
    try {
      final res = await _dio.post(
        '/auth/sync',
        data: body.isEmpty ? null : body,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = (e.response?.data as Map?)?['detail']?.toString();
      throw AppException.server(detail ?? 'Erreur de synchronisation');
    }
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _syncUser(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AppException.unknown(_firebaseMessage(e.code));
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final googleSignIn = kIsWeb
          ? GoogleSignIn(clientId: AppConstants.googleWebClientId)
          : GoogleSignIn(serverClientId: AppConstants.googleWebClientId);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw AppException.unknown('Connexion annulée');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return _syncUser(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AppException.unknown(_firebaseMessage(e.code));
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown('Erreur Google Sign-In');
    }
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String? fullName,
    String? referralCode,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (fullName != null && fullName.isNotEmpty) {
        await cred.user!.updateDisplayName(fullName.trim());
      }
      return _syncUser(cred.user!, fullName: fullName, referralCode: referralCode);
    } on FirebaseAuthException catch (e) {
      throw AppException.unknown(_firebaseMessage(e.code));
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn().signOut(),
    ]);
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException.unknown(_firebaseMessage(e.code));
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _syncUser(user);
  }

  String _firebaseMessage(String code) => switch (code) {
        'user-not-found'       => 'Aucun compte avec cet email',
        'wrong-password'       => 'Mot de passe incorrect',
        'invalid-credential'   => 'Email ou mot de passe incorrect',
        'email-already-in-use' => 'Cet email est déjà utilisé',
        'weak-password'        => 'Le mot de passe doit faire au moins 6 caractères',
        'invalid-email'        => 'Adresse email invalide',
        'too-many-requests'    => 'Trop de tentatives, réessayez plus tard',
        'network-request-failed' => 'Pas de connexion internet',
        'user-disabled'        => 'Ce compte a été désactivé',
        _                      => 'Erreur d\'authentification ($code)',
      };
}
