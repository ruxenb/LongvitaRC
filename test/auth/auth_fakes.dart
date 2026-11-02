// Test-only fakes for CHARLIE-AUTH-01. They implement the app interfaces
// (and the concrete service classes' interfaces via `implements`) so no
// Firebase SDK is touched.
import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:longvita/firebase/analytics_service.dart';
import 'package:longvita/firebase/crashlytics_service.dart';
import 'package:longvita/firebase/notification_service.dart';
import 'package:longvita/firebase/remote_config_service.dart';
import 'package:longvita/firebase/storage_service.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/models/meal_plan_model.dart';
import 'package:longvita/models/user_model.dart';
import 'package:longvita/services/i_auth_service.dart';
import 'package:longvita/services/i_report_service.dart';
import 'package:longvita/viewmodels/session_scoped.dart';

UserModel testUser(String uid, {String role = 'user'}) => UserModel(
      uid: uid,
      email: '$uid@example.test',
      displayName: 'User $uid',
      role: role,
      createdAt: DateTime(2026, 11, 2),
    );

/// Scriptable [IAuthService]. The auth stream behaves like Firebase: it
/// emits the current uid on listen and on every change.
class FakeAuthService implements IAuthService {
  final _uidController = StreamController<String?>.broadcast();
  String? _uid;
  UserModel? _cached;

  /// Next result of [signInWithGoogle]; a Completer lets tests hold the
  /// picker open.
  Completer<AuthSignInResult>? pendingSignIn;
  AuthSignInResult nextSignIn = const AuthSignInCancelled();

  /// Per-call profile outcomes; a [AuthFailure] entry is thrown.
  final List<Object> profileResults = [];

  int signInCalls = 0;
  int loadProfileCalls = 0;
  int signOutCalls = 0;
  bool failSignOut = false;

  FakeAuthService({String? initialUid}) : _uid = initialUid;

  @override
  Stream<String?> get authUidChanges async* {
    yield _uid;
    yield* _uidController.stream;
  }

  @override
  String? get currentUid => _uid;

  @override
  UserModel? get currentUser => _cached?.uid == _uid ? _cached : null;

  /// Simulates Firebase reporting a different user (restore / revoke).
  void emitUid(String? uid) {
    _uid = uid;
    _uidController.add(uid);
  }

  @override
  Future<AuthSignInResult> signInWithGoogle() async {
    signInCalls++;
    final result =
        pendingSignIn != null ? await pendingSignIn!.future : nextSignIn;
    if (result is AuthSignInSucceeded) emitUid(result.uid);
    return result;
  }

  @override
  Future<UserModel> loadProfile(String uid) async {
    loadProfileCalls++;
    await Future<void>.delayed(Duration.zero);
    final outcome =
        profileResults.isEmpty ? testUser(uid) : profileResults.removeAt(0);
    if (outcome is AuthFailure) throw outcome;
    return _cached = outcome as UserModel;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (failSignOut) throw Exception('sign-out failed');
    _cached = null;
    emitUid(null);
  }
}

class FakeAnalytics implements AnalyticsService {
  final List<String?> userIds = [];
  final List<String> events = [];

  @override
  Future<void> setUserId(String? uid) async => userIds.add(uid);

  @override
  Future<void> logLogin({String method = 'google'}) async =>
      events.add('login:$method');

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async =>
      events.add(name);

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class FakeCrashlytics implements CrashlyticsService {
  final List<String> userIds = [];
  final List<Object?> errors = [];
  final Map<String, Object> keys = {};

  @override
  Future<void> setUserId(String uid) async => userIds.add(uid);

  @override
  Future<void> setCustomKey(String key, Object value) async =>
      keys[key] = value;

  @override
  Future<void> recordError(dynamic exception, StackTrace? stack,
          {dynamic reason, bool fatal = false}) async =>
      errors.add(exception);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeNotificationService implements NotificationService {
  final List<RemoteMessage> history = [];
  int initializeCalls = 0;

  @override
  List<RemoteMessage> get messages => List.unmodifiable(history);

  @override
  Future<void> initialize() async => initializeCalls++;

  @override
  void clearHistory() => history.clear();

  @override
  Future<String?> getToken() async => null;
}

class FakeStorageService implements StorageService {
  @override
  Future<String?> uploadReportPdf({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
    return 'https://storage.test/reports/$uid/$fileName';
  }
}

class FakeReportService implements IReportService {
  @override
  Future<Uint8List> generateMealPlanPdf(MealPlanModel plan) async =>
      Uint8List.fromList([1, 2, 3]);
}

/// Records session callbacks in order.
class RecordingSession implements SessionScoped {
  final List<String> calls = [];

  @override
  void onSessionStarted(UserModel user) => calls.add('start:${user.uid}');

  @override
  void clearSession() => calls.add('clear');
}

class FakeRemoteConfig implements RemoteConfigService {
  @override
  int get maxRecommendations => 5;

  @override
  bool get enableLongevityScore => true;

  @override
  String get bannerAnnouncement => '';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
