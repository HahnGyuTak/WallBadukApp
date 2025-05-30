// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyABhyaxUkCJok3KWb-aSP1XGwd5U-0X2WQ',
    appId: '1:350518272438:web:d49c45dee65013633f6117',
    messagingSenderId: '350518272438',
    projectId: 'wallbaduk',
    authDomain: 'wallbaduk.firebaseapp.com',
    storageBucket: 'wallbaduk.firebasestorage.app',
    measurementId: 'G-YVPJH50XVY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA43JnvRTrCch4tZfR-gRmrmPt15Qpg70Y',
    appId: '1:350518272438:android:dcf690f50a8a91503f6117',
    messagingSenderId: '350518272438',
    projectId: 'wallbaduk',
    storageBucket: 'wallbaduk.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD3cXynACM4Dl48Ud-vqhZCMwN6MeOAAbM',
    appId: '1:350518272438:ios:e29039db112909c03f6117',
    messagingSenderId: '350518272438',
    projectId: 'wallbaduk',
    storageBucket: 'wallbaduk.firebasestorage.app',
    iosBundleId: 'com.example.wallBaduApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD3cXynACM4Dl48Ud-vqhZCMwN6MeOAAbM',
    appId: '1:350518272438:ios:e29039db112909c03f6117',
    messagingSenderId: '350518272438',
    projectId: 'wallbaduk',
    storageBucket: 'wallbaduk.firebasestorage.app',
    iosBundleId: 'com.example.wallBaduApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyABhyaxUkCJok3KWb-aSP1XGwd5U-0X2WQ',
    appId: '1:350518272438:web:e3e5f9811a10c69f3f6117',
    messagingSenderId: '350518272438',
    projectId: 'wallbaduk',
    authDomain: 'wallbaduk.firebaseapp.com',
    storageBucket: 'wallbaduk.firebasestorage.app',
    measurementId: 'G-RE2DRFWRRV',
  );
}
