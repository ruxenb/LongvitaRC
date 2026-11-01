import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  Future<void> setUserId(String uid) async {
    try {
      await _crashlytics.setUserIdentifier(uid);
    } catch (_) {}
  }

  Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (_) {}
  }

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {}
  }

  void triggerTestCrash() {
    _crashlytics.crash();
  }
}
