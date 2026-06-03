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
        return ios;
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7MLtXiVGa4sJgohuxjC2ZVObz_jt1ew8',
    appId: '1:212773196919:ios:8e554b7af56919c1d0e272',
    messagingSenderId: '212773196919',
    projectId: 'smartattend-873ba',
    storageBucket: 'smartattend-873ba.firebasestorage.app',
    iosBundleId: 'com.example.smartAttend',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7MLtXiVGa4sJgohuxjC2ZVObz_jt1ew8',
    appId: '1:212773196919:android:placeholder',
    messagingSenderId: '212773196919',
    projectId: 'smartattend-873ba',
    storageBucket: 'smartattend-873ba.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7MLtXiVGa4sJgohuxjC2ZVObz_jt1ew8',
    appId: '1:212773196919:web:placeholder',
    messagingSenderId: '212773196919',
    projectId: 'smartattend-873ba',
    storageBucket: 'smartattend-873ba.firebasestorage.app',
    authDomain: 'smartattend-873ba.firebaseapp.com',
  );
}
