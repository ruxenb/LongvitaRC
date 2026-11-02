// S4-10: the export flow keeps the PDF on the device, reuses its id on retry,
// and opens it for the current session only. Uses fakes: the plan is a fixture
// and no Storage bucket or Android share sheet is involved.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/models/upload_failure.dart';
import 'package:longvita/models/view_state.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';

import '../auth/auth_fakes.dart';
import '../auth/session_isolation_test.dart' show planFor;

/// Scripts upload outcomes and records every call.
class ScriptedStorage extends FakeStorageService {
  /// Next outcomes: null fails the upload as an unknown error.
  final List<Object?> results = [];
  final List<String> fileNames = [];
  final List<Uint8List> uploads = [];

  @override
  Future<String> uploadReportPdf({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    fileNames.add(fileName);
    uploads.add(bytes);
    if (results.isEmpty) return 'https://storage.test/reports/$uid/$fileName';
    final result = results.removeAt(0) ?? const UploadFailure(UploadFailureKind.unknown);
    if (result is UploadFailure) throw result;
    return result as String;
  }
}

class CountingReport extends FakeReportService {
  int calls = 0;

  @override
  Future<Uint8List> generateMealPlanPdf(plan) async {
    calls++;
    return Uint8List.fromList([1, 2, 3]);
  }
}

class HeldSaveStore extends FakeLocalReportStore {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<File> save({
    required String uid,
    required String exportId,
    required Uint8List bytes,
  }) async {
    started.complete();
    await release.future;
    return super.save(uid: uid, exportId: exportId, bytes: bytes);
  }
}

class FailingDeleteStore extends FakeLocalReportStore {
  @override
  Future<void> deleteAll({required String uid}) async =>
      throw const FileSystemException('locked');
}

void main() {
  late FakeAuthService auth;
  late FakeAnalytics analytics;
  late FakeCrashlytics crashlytics;
  late ScriptedStorage storage;
  late CountingReport report;
  late FakeLocalReportStore store;
  late FakeReportViewer viewer;
  late ProfileViewModel profile;
  late AuthViewModel session;

  void wire({FakeLocalReportStore? customStore}) {
    store = customStore ?? FakeLocalReportStore();
    profile = ProfileViewModel(
      authService: auth,
      storageService: storage,
      notificationService: FakeNotificationService(),
      reportService: report,
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
  }

  Future<void> signIn(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    auth.nextSignIn = AuthSignInSucceeded(uid);
    await session.signInWithGoogle();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(session.currentUser?.uid, uid);
  }

  setUp(() {
    auth = FakeAuthService();
    analytics = FakeAnalytics();
    crashlytics = FakeCrashlytics();
    storage = ScriptedStorage();
    report = CountingReport();
    viewer = FakeReportViewer();
    wire();
  });

  group('saving before upload', () {
    test('a successful export keeps the file and uploads under its id', () async {
      await signIn('uid-a');

      await profile.exportAndUploadPdf(planFor('uid-a'));

      final export = profile.lastExport!;
      expect(export.planId, 'plan-uid-a');
      expect(store.files['uid-a/${export.exportId}'], [1, 2, 3]);
      expect(storage.fileNames, [export.fileName]);
      expect(profile.lastUploadedUrl, contains(export.fileName));
      expect(profile.exportState, isA<ViewStateSuccess<String>>());
    });

    test('a failed upload keeps the file and says so', () async {
      await signIn('uid-a');
      storage.results.add(null);

      await profile.exportAndUploadPdf(planFor('uid-a'));

      expect(profile.lastExport, isNotNull);
      expect(store.files, hasLength(1));
      expect(profile.lastUploadedUrl, isNull);
      final state = profile.exportState as ViewStateError<String>;
      expect(state.message, contains('đã lưu trên máy'));
      expect(analytics.events.where((e) => e.startsWith('export_report')), isEmpty);
    });

    test('a failed save stops before the upload', () async {
      store.saveError = const FileSystemException('disk full');
      await signIn('uid-a');

      await profile.exportAndUploadPdf(planFor('uid-a'));

      expect(storage.fileNames, isEmpty);
      expect(profile.lastExport, isNull);
      expect(profile.exportState, isA<ViewStateError<String>>());
      expect(crashlytics.errors, hasLength(1));
    });

    test('a plan id is made safe for a file name', () async {
      await signIn('uid-a');
      final plan = planFor('uid-a').copyWith(id: '../a b');

      await profile.exportAndUploadPdf(plan);

      expect(profile.lastExport!.exportId, matches(RegExp(r'^ab_\d+$')));
    });

    test('a plan with no usable id still exports', () async {
      await signIn('uid-a');

      await profile.exportAndUploadPdf(planFor('uid-a').copyWith(id: '///'));

      expect(profile.lastExport!.exportId, matches(RegExp(r'^plan_\d+$')));
    });

    test('a new export clears the URL of the previous one', () async {
      await signIn('uid-a');
      await profile.exportAndUploadPdf(planFor('uid-a'));
      expect(profile.lastUploadedUrl, isNotNull);
      storage.results.add(null);

      await profile.exportAndUploadPdf(planFor('uid-a'));

      expect(profile.lastUploadedUrl, isNull);
    });
  });

  group('retryUpload', () {
    test('reuses the same id and file, without generating again', () async {
      await signIn('uid-a');
      storage.results.add(null);
      await profile.exportAndUploadPdf(planFor('uid-a'));
      final export = profile.lastExport!;

      await profile.retryUpload();

      expect(report.calls, 1);
      expect(storage.fileNames, [export.fileName, export.fileName]);
      expect(storage.uploads.last, [1, 2, 3]);
      expect(profile.lastExport, same(export));
      expect(profile.lastUploadedUrl, isNotNull);
      expect(profile.exportState, isA<ViewStateSuccess<String>>());
      expect(analytics.events, contains('export_report:1:0'));
    });

    test('a second failure keeps the file for another retry', () async {
      await signIn('uid-a');
      storage.results.addAll([null, null]);
      await profile.exportAndUploadPdf(planFor('uid-a'));

      await profile.retryUpload();

      expect(profile.lastExport, isNotNull);
      expect(profile.exportState, isA<ViewStateError<String>>());
    });

    test('a missing file asks for a new export', () async {
      await signIn('uid-a');
      storage.results.add(null);
      await profile.exportAndUploadPdf(planFor('uid-a'));
      store.files.clear();

      await profile.retryUpload();

      expect(profile.lastExport, isNull);
      expect(storage.fileNames, hasLength(1));
      expect(profile.exportState, isA<ViewStateError<String>>());
    });

    test('does nothing with no export', () async {
      await signIn('uid-a');

      await profile.retryUpload();

      expect(storage.fileNames, isEmpty);
      expect(profile.exportState, isA<ViewStateIdle<String>>());
    });
  });

  group('open and share', () {
    test('use the saved file, also after a failed upload', () async {
      await signIn('uid-a');
      storage.results.add(null);
      await profile.exportAndUploadPdf(planFor('uid-a'));
      final name = profile.lastExport!.fileName;

      expect(await profile.previewLastExport(), isTrue);
      expect(await profile.shareLastExport(), isTrue);

      expect(viewer.previewed, [name]);
      expect(viewer.shared, [name]);
    });

    test('return false with no export', () async {
      await signIn('uid-a');

      expect(await profile.previewLastExport(), isFalse);
      expect(await profile.shareLastExport(), isFalse);
      expect(viewer.previewed, isEmpty);
    });

    test('return false when the file is gone', () async {
      await signIn('uid-a');
      await profile.exportAndUploadPdf(planFor('uid-a'));
      store.files.clear();

      expect(await profile.shareLastExport(), isFalse);
      expect(viewer.shared, isEmpty);
    });

    test('report a viewer failure instead of throwing', () async {
      await signIn('uid-a');
      await profile.exportAndUploadPdf(planFor('uid-a'));
      viewer.error = Exception('no viewer');

      expect(await profile.previewLastExport(), isFalse);
      expect(crashlytics.errors, hasLength(1));
    });
  });

  group('session change', () {
    test('B cannot open or retry the export of A', () async {
      await signIn('uid-a');
      storage.results.add(null);
      await profile.exportAndUploadPdf(planFor('uid-a'));

      await session.signOut();
      await signIn('uid-b');

      expect(profile.lastExport, isNull);
      expect(await profile.shareLastExport(), isFalse);
      await profile.retryUpload();
      expect(storage.fileNames, hasLength(1));
      expect(viewer.shared, isEmpty);
    });

    test('sign-out removes the files of A from the device', () async {
      await signIn('uid-a');
      await profile.exportAndUploadPdf(planFor('uid-a'));
      store.files['uid-b/other'] = Uint8List.fromList([9]);

      await session.signOut();

      expect(store.files.keys, ['uid-b/other']);
    });

    test('a failed removal is recorded and does not break sign-out', () async {
      final failing = FailingDeleteStore();
      wire(customStore: failing);
      await signIn('uid-a');

      await session.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(session.currentUser, isNull);
      expect(crashlytics.errors, hasLength(1));
    });

    test('logout during save neither sets the export nor uploads', () async {
      final held = HeldSaveStore();
      wire(customStore: held);
      await signIn('uid-a');

      final export = profile.exportAndUploadPdf(planFor('uid-a'));
      await held.started.future;
      await session.signOut();
      await signIn('uid-b');
      held.release.complete();
      await export;

      expect(profile.lastExport, isNull);
      expect(storage.fileNames, isEmpty);
      expect(profile.exportState, isA<ViewStateIdle<String>>());
      expect(store.files, isEmpty, reason: 'the late save is removed too');
    });
  });

  group('upload failures', () {
    for (final (kind, text) in const [
      (UploadFailureKind.network, 'mất kết nối'),
      (UploadFailureKind.denied, 'chưa có quyền'),
      (UploadFailureKind.notConfigured, 'chưa sẵn sàng'),
      (UploadFailureKind.quota, 'dung lượng'),
      (UploadFailureKind.unknown, 'chưa tải lên được'),
    ]) {
      test('${kind.name} says why and keeps the file', () async {
        await signIn('uid-a');
        storage.results.add(UploadFailure(kind));

        await profile.exportAndUploadPdf(planFor('uid-a'));

        final state = profile.exportState as ViewStateError<String>;
        expect(state.message, contains(text));
        expect(state.message, contains('đã lưu trên máy'));
        expect(profile.canRetryUpload, isTrue);
        expect(store.files, hasLength(1));
      });
    }

    test('a lost connection is not recorded as an app error', () async {
      await signIn('uid-a');
      storage.results.add(const UploadFailure(UploadFailureKind.network));

      await profile.exportAndUploadPdf(planFor('uid-a'));

      expect(crashlytics.errors, isEmpty);
    });

    test('a denied upload is recorded', () async {
      await signIn('uid-a');
      storage.results.add(const UploadFailure(UploadFailureKind.denied));

      await profile.exportAndUploadPdf(planFor('uid-a'));

      expect(crashlytics.errors, hasLength(1));
    });
  });
}
