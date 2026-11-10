// Existing Firebase registration, separated by client during CM-02.
// No Firebase app registration or configure operation was performed.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'This web client is not configured for the current platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCl2FFGe76YoWY8yj55iPC5oDl54rQS98s',
    appId: '1:1041459198085:web:26af5f87579b21588e11ec',
    messagingSenderId: '1041459198085',
    projectId: 'longvita-8da7e',
    authDomain: 'longvita-8da7e.firebaseapp.com',
    storageBucket: 'longvita-8da7e.firebasestorage.app',
    measurementId: 'G-N0EN7XPNE0',
  );
}
