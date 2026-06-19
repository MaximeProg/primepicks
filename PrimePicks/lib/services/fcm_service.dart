import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';

class FcmService {
  final ApiClient _api;
  FcmService(this._api);

  Future<void> init() async {
    if (kIsWeb) return;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
  }

  Future<void> deleteToken() async {
    if (kIsWeb) return;
    try {
      final deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';
      await _api.delete('/notifications/token?device_type=$deviceType');
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<void> _registerToken(String token) async {
    try {
      final deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';
      await _api.post(
        '/notifications/token',
        data: {'token': token, 'device_type': deviceType},
      );
    } catch (_) {}
  }
}

final fcmServiceProvider = Provider<FcmService>(
    (ref) => FcmService(ref.read(apiClientProvider)));
