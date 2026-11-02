// PM-PDF-01: one export or retry runs at a time, and everything the app shows
// (local file, URL, state, progress, event) belongs to that one operation.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/models/meal_plan_model.dart';
import 'package:longvita/models/upload_failure.dart';
import 'package:longvita/models/view_state.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';

import '../auth/auth_fakes.dart';
import '../auth/session_isolation_test.dart' show planFor;

class HeldUpload {
  final String fileName;
  final void Function(double)? onProgress;
  final Completer<String> result = Completer();

  HeldUpload(this.fileName, this.onProgress);

  void succeed() =>
      result.complete('https://storage.test/$fileName');

  void fail([UploadFailureKind kind = UploadFailureKind.unknown]) =>
      result.completeError(UploadFailure(kind));
}

class HeldStorage extends FakeStorageService {
  final List<HeldUpload> uploads = [];

  @override
  Future<String> uploadReportPdf({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) {
    final upload = HeldUpload(fileName, onProgress);
    uploads.add(upload);
    return upload.result.future;
  }
}

void main() {
  late FakeAuthService auth;
  late FakeAnalytics analytics;
  late FakeCrashlytics crashlytics;
  late HeldStorage storage;
  late FakeLocalReportStore store;
  late ProfileViewModel profile;
  late AuthViewModel session;

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

  Future<void> signIn(String uid) async {
    await settle();
    auth.nextSignIn = AuthSignInSucceeded(uid);
    await session.signInWithGoogle();
    await settle();
    expect(session.currentUser?.uid, uid);
  }

  MealPlanModel plan(String id) => planFor('uid-a').copyWith(id: id);

  /// Starts an export; `await settle()` then waits until its upload is held.
  Future<void> startExport(String planId) =>
      profile.exportAndUploadPdf(plan(planId));

  /// The invariant of PM-PDF-01: URL and local file are the same export.
  void expectConsistent() {
    final url = profile.lastUploadedUrl;
    if (url != null) expect(url, endsWith(profile.lastExport!.fileName));
    final state = profile.exportState;
    if (state is ViewStateSuccess<String>) expect(state.data, url);
  }

  setUp(() {
    auth = FakeAuthService();
    analytics = FakeAnalytics();
    crashlytics = FakeCrashlytics();
    storage = HeldStorage();
    store = FakeLocalReportStore();
    profile = ProfileViewModel(
      authService: auth,
      storageService: storage,
      notificationService: FakeNotificationService(),
      reportService: FakeReportService(),
      reportStore: store,
      reportViewer: FakeReportViewer(),
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
  });

  group('one operation at a time', () {
    test('a second export while one runs starts nothing', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();
      final fileBefore = profile.lastExport;

      await profile.exportAndUploadPdf(plan('second'));

      expect(profile.isExporting, isTrue);
      expect(storage.uploads, hasLength(1));
      expect(store.files, hasLength(1));
      expect(profile.lastExport, same(fileBefore));
      expect(profile.exportState, isA<ViewStateLoading<String>>(),
          reason: 'the ignored call must not read as a result');

      storage.uploads.single.succeed();
      await first;
      expectConsistent();
      expect(profile.lastExport!.fileName, startsWith('first_'));
    });

    test('a retry while an export runs starts nothing', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();

      await profile.retryUpload();

      expect(storage.uploads, hasLength(1));
      storage.uploads.single.succeed();
      await first;
      expectConsistent();
    });

    test('an export while a retry runs starts nothing', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();
      storage.uploads.single.fail();
      await first;

      final retry = profile.retryUpload();
      await settle();
      await profile.exportAndUploadPdf(plan('second'));

      expect(storage.uploads, hasLength(2));
      expect(store.files, hasLength(1));
      storage.uploads.last.succeed();
      await retry;
      expectConsistent();
      expect(profile.lastExport!.fileName, startsWith('first_'));
    });

    test('a new export can start after the previous one ends', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();
      storage.uploads.single.succeed();
      await first;
      expect(profile.isExporting, isFalse);

      final second = startExport('second');

      await settle();
      storage.uploads.last.succeed();
      await second;

      expectConsistent();
      expect(profile.lastExport!.fileName, startsWith('second_'));
      expect(store.files, hasLength(2));
    });

    for (final (name, finish) in <(String, void Function(HeldUpload))>[
      ('success', (u) => u.succeed()),
      ('typed failure', (u) => u.fail()),
      ('error', (u) => u.result.completeError(Exception('network'))),
    ]) {
      test('the busy state ends after $name', () async {
        await signIn('uid-a');
        final first = startExport('first');
        await settle();
        expect(profile.isExporting, isTrue);

        finish(storage.uploads.single);
        await first;

        expect(profile.isExporting, isFalse);
      });
    }

    test('the busy state ends when generating or saving fails', () async {
      store.saveError = Exception('disk full');
      await signIn('uid-a');

      await profile.exportAndUploadPdf(plan('first'));

      expect(profile.isExporting, isFalse);
      expect(profile.exportState, isA<ViewStateError<String>>());
    });
  });

  group('late callbacks of a finished operation', () {
    test('progress from an ended upload does not touch the next one', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();
      final oldUpload = storage.uploads.single;
      oldUpload.fail();
      await first;

      final second = startExport('second');

      await settle();
      storage.uploads.last.onProgress!(0.3);
      expect(profile.uploadProgress, 0.3);

      oldUpload.onProgress!(0.9);

      expect(profile.uploadProgress, 0.3);
      storage.uploads.last.succeed();
      await second;
      expectConsistent();
    });

    test('progress after an upload ended leaves it unchanged', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();
      final upload = storage.uploads.single;
      upload.onProgress!(0.4);
      upload.fail();
      await first;

      upload.onProgress!(0.9);

      expect(profile.uploadProgress, 0.4);
    });
  });

  group('session change', () {
    test('an upload of A does not block B, and ends without touching B', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();
      final oldUpload = storage.uploads.single;

      await session.signOut();
      await signIn('uid-b');
      expect(profile.isExporting, isFalse);

      final second = startExport('second');

      await settle();
      expect(profile.isExporting, isTrue);

      oldUpload.succeed();
      await first;

      expect(profile.isExporting, isTrue, reason: 'B is still uploading');
      expect(profile.lastUploadedUrl, isNull);

      storage.uploads.last.succeed();
      await second;
      expectConsistent();
      expect(profile.lastExport!.fileName, startsWith('second_'));
      expect(profile.isExporting, isFalse);
    });

    test('A signing back in is not blocked or overwritten by the old upload',
        () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();
      final oldUpload = storage.uploads.single;

      await session.signOut();
      await signIn('uid-a');
      final second = startExport('second');
      await settle();

      oldUpload.succeed();
      await first;
      expect(profile.lastUploadedUrl, isNull);

      storage.uploads.last.succeed();
      await second;
      expectConsistent();
      expect(profile.lastExport!.fileName, startsWith('second_'));
    });
  });

  group('cancel', () {
    test('stops the upload, keeps the file and allows a retry', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();
      expect(profile.canCancelUpload, isTrue);

      profile.cancelUpload();

      expect(storage.cancelCalls, 1);
      expect(profile.canCancelUpload, isFalse, reason: 'reported at once');
      expect(profile.isExporting, isFalse);
      expect(profile.exportState, isA<ViewStateEmpty<String>>());
      expect(profile.canRetryUpload, isTrue);
      expect(store.files, hasLength(1));

      storage.uploads.single.fail(UploadFailureKind.cancelled);
      await first;
      expect(profile.exportState, isA<ViewStateEmpty<String>>());
      expect(crashlytics.errors, isEmpty);
    });

    test('a task that still finishes after cancel changes nothing', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();

      profile.cancelUpload();
      storage.uploads.single.succeed();
      await first;

      expect(profile.lastUploadedUrl, isNull);
      expect(profile.canRetryUpload, isTrue);
      expect(analytics.events.where((e) => e.startsWith('export_report')), isEmpty);
    });

    test('a retry can start right after cancel', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();
      profile.cancelUpload();

      final retry = profile.retryUpload();
      await settle();
      storage.uploads.first.fail(UploadFailureKind.cancelled);
      await first;

      expect(profile.isExporting, isTrue, reason: 'the old task must not end the retry');
      storage.uploads.last.succeed();
      await retry;
      expectConsistent();
      expect(profile.lastUploadedUrl, isNotNull);
    });

    test('does nothing when no upload runs', () async {
      await signIn('uid-a');

      profile.cancelUpload();

      expect(storage.cancelCalls, 0);
    });

    test('sign-out stops the running upload', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();

      await session.signOut();

      expect(storage.cancelCalls, 1);
      storage.uploads.single.fail(UploadFailureKind.cancelled);
      await first;
      expect(profile.exportState, isA<ViewStateIdle<String>>());
    });

    test('sign-out with nothing running cancels nothing', () async {
      await signIn('uid-a');

      await session.signOut();

      expect(storage.cancelCalls, 0);
    });
  });

  group('canRetryUpload', () {
    test('is true only after a failed upload, and while nothing runs', () async {
      await signIn('uid-a');
      expect(profile.canRetryUpload, isFalse);

      final first = startExport('first');

      await settle();
      expect(profile.canRetryUpload, isFalse, reason: 'still uploading');

      storage.uploads.single.fail();
      await first;
      expect(profile.canRetryUpload, isTrue);

      final retry = profile.retryUpload();
      await settle();
      expect(profile.canRetryUpload, isFalse, reason: 'retry running');

      storage.uploads.last.succeed();
      await retry;
      expect(profile.canRetryUpload, isFalse, reason: 'already uploaded');
    });

    test('a retry after a successful upload does nothing', () async {
      await signIn('uid-a');
      final first = startExport('first');
      await settle();
      storage.uploads.single.succeed();
      await first;

      await profile.retryUpload();

      expect(storage.uploads, hasLength(1));
    });
  });

  test('the saved file opens while the upload is still running', () async {
    await signIn('uid-a');
    final first = startExport('first');
    await settle();

    expect(await profile.shareLastExport(), isTrue);

    storage.uploads.single.succeed();
    await first;
  });
}
