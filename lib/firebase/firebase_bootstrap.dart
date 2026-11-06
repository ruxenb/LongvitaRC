import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import '../firebase_options.dart';

/// Result of starting Firebase before any SDK service is created.
sealed class BootstrapResult {
  const BootstrapResult();
}

class BootstrapReady extends BootstrapResult {
  const BootstrapReady();
}

class BootstrapFailed extends BootstrapResult {
  /// Short code for the report/log, e.g. `not-configured`, `network`.
  final String code;
  final Object error;
  final StackTrace? stackTrace;

  const BootstrapFailed(this.code, this.error, [this.stackTrace]);

  /// True when the app was built without Firebase configuration
  /// (google-services.json / FirebaseOptions), as opposed to a transient
  /// failure that a retry can fix.
  bool get isConfigurationMissing => code == 'not-configured';
}

/// Initialises Firebase (S3-1). Services that touch `*.instance` must only
/// be created after [BootstrapReady]; on failure the app shows a startup
/// error with retry instead of continuing as if Firebase were ready.
class FirebaseBootstrap {
  final Future<FirebaseApp> Function() _initializeApp;

  /// [initializeApp] defaults to `Firebase.initializeApp` with the options
  /// `flutterfire configure` generated in `firebase_options.dart` (Android
  /// only). They match `android/app/google-services.json`, which stays for
  /// the native resources Crashlytics and Google Sign-in read.
  FirebaseBootstrap({Future<FirebaseApp> Function()? initializeApp})
      : _initializeApp = initializeApp ??
            (() => Firebase.initializeApp(
                options: DefaultFirebaseOptions.currentPlatform));

  Future<BootstrapResult> initialize() async {
    try {
      if (Firebase.apps.isEmpty) await _initializeApp();
      return const BootstrapReady();
    } on FirebaseException catch (e, s) {
      return BootstrapFailed(
          _isMissingConfig('${e.code} ${e.message}') ? 'not-configured' : e.code,
          e,
          s);
    } on PlatformException catch (e, s) {
      // Android reports a missing google-services config as
      // PlatformException(code: "java.lang.Exception: Failed to load
      // FirebaseOptions from resource...", message: "Exception").
      return BootstrapFailed(
          _isMissingConfig('${e.code} ${e.message}') ? 'not-configured' : 'platform',
          e,
          s);
    } catch (e, s) {
      return BootstrapFailed(
          _isMissingConfig(e.toString()) ? 'not-configured' : 'unknown', e, s);
    }
  }

  static bool _isMissingConfig(String? message) {
    final text = (message ?? '').toLowerCase();
    return text.contains('google-services') ||
        text.contains('failed to load firebaseoptions') ||
        text.contains('no firebase app') ||
        text.contains('values.xml') ||
        text.contains('firebaseoptions');
  }
}
