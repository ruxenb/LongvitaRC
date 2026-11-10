// PM-S3-5-04: the PDFs of an ended session are removed without waiting. When
// the same user signs back in and exports before that removal finishes, the
// old files must go and the new one must stay usable. Real LocalReportStore in
// a temporary folder; auth, metadata and viewer are fakes; the default Final flow is used.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_core/models/auth_state.dart';
import 'package:longvita/services/local_report_store.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';

import '../auth/auth_fakes.dart';
import '../auth/session_isolation_test.dart' show planFor;

/// Reports each save as it is requested, before it joins the queue of its
/// uid. Waiting inside the save itself would hang, because a held removal
/// runs first.
class _SignalingReportStore extends LocalReportStore {
  _SignalingReportStore({required this.onSave, required super.baseDirectory});

  final void Function() onSave;

  @override
  Future<File> save({
    required String uid,
    required String exportId,
    required Uint8List bytes,
  }) {
    onSave();
    return super.save(uid: uid, exportId: exportId, bytes: bytes);
  }
}

void main() {
  late Directory dir;
  late FakeAuthService auth;
  late FakeReportViewer viewer;
  late ProfileViewModel profile;
  late AuthViewModel session;
  late LocalReportStore store;

  /// While set, the next folder lookup (the removal's) waits for it.
  Completer<void>? holdNextLookup;
  Completer<void>? removalStarted;

  /// Completed when the next save is requested; set only around the export
  /// under test.
  Completer<void>? saveRequested;

  /// The gate a test holds, released in tearDown if an assertion failed first.
  Completer<void>? gate;

  setUp(() async {
    holdNextLookup = null;
    removalStarted = null;
    saveRequested = null;
    gate = null;
    dir = await Directory.systemTemp.createTemp('longvita_session_cleanup');
    auth = FakeAuthService(initialUid: 'uid-a');
    viewer = FakeReportViewer();
    final analytics = FakeAnalytics();
    final crashlytics = FakeCrashlytics();
    store = _SignalingReportStore(
      onSave: () {
        final requested = saveRequested;
        if (requested != null && !requested.isCompleted) {
          requested.complete();
        }
      },
      baseDirectory: () async {
        final hold = holdNextLookup;
        if (hold != null) {
          holdNextLookup = null;
          removalStarted?.complete();
          await hold.future;
        }
        return dir;
      },
    );
    profile = ProfileViewModel(
      metadataRepository: FakeReportMetadataRepository(),
      authService: auth,
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
    // The restored session of A is ready once its profile has loaded.
    if (session.currentUser == null) {
      final ready = Completer<void>();
      void onChange() {
        if (session.currentUser != null && !ready.isCompleted) ready.complete();
      }

      session.addListener(onChange);
      await ready.future;
      session.removeListener(onChange);
    }
  });

  tearDown(() async {
    final held = gate;
    if (held != null && !held.isCompleted) held.complete();
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

    final release = gate = holdNextLookup = Completer<void>();
    removalStarted = Completer<void>();
    await session.signOut();
    await removalStarted!.future;
    auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    await session.signInWithGoogle();
    expect(session.currentUser?.uid, 'uid-a', reason: 'profile loaded');

    // The new export asks to save while the old removal is still held, and
    // the save runs only after it.
    final requested = saveRequested = Completer<void>();
    // Same user, another plan: an export id is the plan id plus the current
    // millisecond, so the same plan could repeat the first export's id.
    final export = profile.exportAndUploadPdf(
      planFor('uid-a').copyWith(id: 'second-plan'),
    );
    await requested.future;
    release.complete();
    await export;

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

    final release = gate = holdNextLookup = Completer<void>();
    removalStarted = Completer<void>();
    await session.signOut();
    await removalStarted!.future;
    release.complete();
    // Queued after the removal for the same uid, so it ends after it.
    expect(await store.find(uid: 'uid-a', exportId: oldId), isNull);

    expect(fileOf(oldId).existsSync(), isFalse);
    expect(Directory('${dir.path}/reports/uid-a').existsSync(), isFalse);
  });
}
