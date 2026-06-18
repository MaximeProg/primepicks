import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web; // fallback desktop dev
    }
  }

  // Web — même projet Firebase que l'admin Next.js
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDh8u06AWI3w79SeRbI2JIkxAuzoOmdKJw',
    appId: '1:372184492195:web:287ffb881de25520af7716',
    messagingSenderId: '372184492195',
    projectId: 'coupons-8ffe5',
    authDomain: 'coupons-8ffe5.firebaseapp.com',
    storageBucket: 'coupons-8ffe5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAutQiG4YQm-lOCttQDv8q-3CE23Kb7Z8g',
    appId: '1:372184492195:android:82e4361ed09c9259af7716',
    messagingSenderId: '372184492195',
    projectId: 'coupons-8ffe5',
    storageBucket: 'coupons-8ffe5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCXFEJw1YAxi1uTqBBRK4weC1SE6XrrmUw',
    appId: '1:372184492195:ios:1d6c5a3d1bdc0daeaf7716',
    messagingSenderId: '372184492195',
    projectId: 'coupons-8ffe5',
    storageBucket: 'coupons-8ffe5.firebasestorage.app',
    iosBundleId: 'com.primepicks.app',
    iosClientId: '372184492195-c7ndt9k9m6nbsl2k2f26gmmksb8lalrc.apps.googleusercontent.com',
  );
}
