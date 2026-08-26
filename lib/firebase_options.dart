import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

class MleyFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isIOS) return ios;
    if (Platform.isAndroid) return android;
    throw UnsupportedError('Firebase yalnız Android ve iOS için yapılandırılmıştır.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyChNxqMDvar2NApHBmYqwDUJ4dk70Dh74E',
    appId: '1:971745236874:android:9671d1f51e001b8be35a73',
    messagingSenderId: '971745236874',
    projectId: 'mleysoft-tr',
    storageBucket: 'mleysoft-tr.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDlwXoKnMIBHbZPJnsvxRvFZJmBH2AvjA4',
    appId: '1:971745236874:ios:a9aa221699f5aa73e35a73',
    messagingSenderId: '971745236874',
    projectId: 'mleysoft-tr',
    storageBucket: 'mleysoft-tr.firebasestorage.app',
    iosBundleId: 'com.mleysoft.ik',
  );
}
