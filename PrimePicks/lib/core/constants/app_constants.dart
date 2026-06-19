import 'package:flutter/foundation.dart';

class AppConstants {
  // Sur web (dev) → localhost ; sur émulateur Android → 10.0.2.2 ; device réel → IP du serveur
  static String get baseUrl {
    if (kIsWeb) return 'https://primepicks-bqpo.onrender.com/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://primepicks-bqpo.onrender.com/api/v1';
    }
    return 'https://primepicks-bqpo.onrender.com/api/v1';
  }

  static const String appName = 'PrimePicks';
  static const String packageName = 'com.primepicks.app';

  // Google Sign-In web client ID
  static const String googleWebClientId =
      '372184492195-ttqm08nbiri049g2ojfbn12kcgs1ad21.apps.googleusercontent.com';

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;

  // Retry
  static const int maxRetries = 2;
}
