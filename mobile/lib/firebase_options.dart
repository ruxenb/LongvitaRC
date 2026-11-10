// Existing Firebase registration, separated by client during CM-02.
// No Firebase app registration or configure operation was performed.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'This mobile client is not configured for the current platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZIYexmzf-lwnUT3PFvcR60fXtLB5zNAY',
    appId: '1:1041459198085:android:33939d119fc3892d8e11ec',
    messagingSenderId: '1041459198085',
    projectId: 'longvita-8da7e',
    storageBucket: 'longvita-8da7e.firebasestorage.app',
  );
}
