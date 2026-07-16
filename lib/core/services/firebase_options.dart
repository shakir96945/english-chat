// File generated with authentic Google Cloud Project configuration.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyATkmt9Xe3xtkFjBL-A_zxW-WAQlFIrmBg',
    appId: '1:365631019633:web:7f6a29d5ec9e82c16ec9e8',
    messagingSenderId: '365631019633',
    projectId: 'ais-asia-east1-d934c79493064f5',
    authDomain: 'ais-asia-east1-d934c79493064f5.firebaseapp.com',
    storageBucket: 'ais-asia-east1-d934c79493064f5.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATkmt9Xe3xtkFjBL-A_zxW-WAQlFIrmBg',
    appId: '1:365631019633:android:820a1bc3ef4629f123ec9e',
    messagingSenderId: '365631019633',
    projectId: 'ais-asia-east1-d934c79493064f5',
    storageBucket: 'ais-asia-east1-d934c79493064f5.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyATkmt9Xe3xtkFjBL-A_zxW-WAQlFIrmBg',
    appId: '1:365631019633:ios:cf29ecb83c41ea1023ec9e',
    messagingSenderId: '365631019633',
    projectId: 'ais-asia-east1-d934c79493064f5',
    storageBucket: 'ais-asia-east1-d934c79493064f5.appspot.com',
    iosBundleId: 'com.englishchat.app',
  );
}
