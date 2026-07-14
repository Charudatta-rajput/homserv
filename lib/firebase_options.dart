import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS is not supported');
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB74Yd_gJu-tluG5AyUBX-983WkqPYBSwg',
    appId: '1:627927765150:android:c9f4158e6d4542881deb8f',
    messagingSenderId: '627927765150',
    projectId: 'homeserv-ac0ae',
    authDomain: 'homeserv-ac0ae.firebaseapp.com',
    databaseURL: 'https://homeserv-ac0ae-default-rtdb.firebaseio.com',
    storageBucket: 'homeserv-ac0ae.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB74Yd_gJu-tluG5AyUBX-983WkqPYBSwg',
    appId: '1:627927765150:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '627927765150',
    projectId: 'homeserv-ac0ae',
    authDomain: 'homeserv-ac0ae.firebaseapp.com',
    databaseURL: 'https://homeserv-ac0ae-default-rtdb.firebaseio.com',
    storageBucket: 'homeserv-ac0ae.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.homserv.homserv',
  );
}