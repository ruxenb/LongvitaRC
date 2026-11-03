// PM-S3-5-04: the PDFs of an ended session are removed without waiting. When
// the same user signs back in and exports before that removal finishes, the
// old files must go and the new one must stay usable. Real LocalReportStore in
// a temporary folder; auth, upload and viewer are fakes.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/services/local_report_store.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';

import '../auth/auth_fakes.dart';
import '../auth/session_isolation_test.dart' show planFor;

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late Directory dir;
  late FakeAuthService auth;
  late FakeReportViewer viewer;
  late ProfileViewModel profile;
  late AuthViewModel session;

  /// While set, the next folder lookup (the removal's) waits for it.
  Completer<void>? holdNextLookup;
  Completer<void>? removalStarted;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('longvita_session_cleanup');
    auth = FakeAuthService(initialUid: 'uid-a');
    viewer = FakeReportViewer();
    final analytics = FakeAnalytics();
    final crashlytics = FakeCrashlytics();
    final store = LocalReportStore(baseDirectory: () async {
      final hold = holdNextLookup;
      if (hold != null) {
        holdNextLookup = null;
        removalStarted?.complete();
        await hold.future;
      }
      return dir;
    });
    profile = ProfileViewModel(
      authService: auth,
      storageService: FakeStorageService(),
      notificationService: FakeNotificationService(),
      reportService: FakeReportService(),
      reportStore: store,
      reportViewer: viewer,
      remoteConfigService: FakeRemoteConfig(),
      crashlyticsService: crashlytics,
      analyticsService: analytics,
    );
    session = AuthViewModel(
      authService: auth,
      analytics: analytics,
      crashlytics: crashlytics,
      sessionScoped: [profile],
    );
    await settle();
  });

  tearDown(() async {
    session.dispose();
    profile.dispose();
    await dir.delete(recursive: true);
  });

  File fileOf(String exportId) =>
      File('${dir.path}/reports/uid-a/$exportId.pdf');

  test('a late removal of the old session keeps the new PDF', () async {
    await profile.exportAndUploadPdf(planFor('uid-a'));
    final oldId = profile.lastExport!.exportId;
    expect(fileOf(oldId).existsSync(), isTrue);

    final release = holdNextLookup = Completer<void>();
    removalStarted = Completer<void>();
    await session.signOut();
    await removalStarted!.future;
    auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    await session.signInWithGoogle();
    await settle();

    // The new export starts while the old removal is still held, and saves
    // only after it.
    final export = profile.exportAndUploadPdf(planFor('uid-a'));
    await settle();
    release.complete();
    await export;
    await settle();

    final newId = profile.lastExport!.exportId;
    expect(newId, isNot(oldId));
    expect(fileOf(oldId).existsSync(), isFalse, reason: 'old session cleaned');
    expect(fileOf(newId).existsSync(), isTrue, reason: 'new PDF kept');

    expect(await profile.previewLastExport(), isTrue);
    expect(await profile.shareLastExport(), isTrue);
    expect(viewer.shared, hasLength(1));
  });

  test('without a re-sign-in the removal still cleans everything', () async {
    await profile.exportAndUploadPdf(planFor('uid-a'));
    final oldId = profile.lastExport!.exportId;

    final release = holdNextLookup = Completer<void>();
    removalStarted = Completer<void>();
    await session.signOut();
    await removalStarted!.future;
    release.complete();
    await settle();

    expect(fileOf(oldId).existsSync(), isFalse);
    expect(Directory('${dir.path}/reports/uid-a').existsSync(), isFalse);
  });
}
