import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/config/pdf_export_mode.dart';
import 'package:longvita/models/report_export.dart';
import 'package:longvita/models/report_metadata.dart';
import 'package:longvita/models/report_metadata_state.dart';
import 'package:longvita/models/view_state.dart';
import 'package:longvita/services/i_report_metadata_repository.dart';
import 'package:longvita/services/local_report_store.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';

import '../auth/auth_fakes.dart';
import '../auth/session_isolation_test.dart' show planFor;

class HeldMetadata implements IReportMetadataRepository {
  final writes = <(String, ReportMetadata, Completer<void>)>[];
  @override
  Future<void> save(String uid, ReportMetadata metadata) {
    final done = Completer<void>();
    writes.add((uid, metadata, done));
    return done.future;
  }
}

class CountingStorage extends FakeStorageService {
  int uploads = 0;
  @override
  Future<String> uploadReportPdf({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double)? onProgress,
  }) async {
    uploads++;
    return 'http://localhost/unused';
  }
}

class HeldAnalytics extends FakeAnalytics {
  final done = Completer<void>();
  @override
  Future<void> logExportReport({
    String topic = 'longevity_meal_plan',
    required int fileSizeKb,
    required int hasShoppingList,
  }) {
    events.add('export_report:$fileSizeKb:$hasShoppingList');
    return done.future;
  }
}

class BrokenDiagnostics extends FakeCrashlytics {
  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async => throw StateError('logger unavailable');
}

class HeldReport extends FakeReportService {
  final started = Completer<void>();
  final done = Completer<Uint8List>();
  @override
  Future<Uint8List> generateMealPlanPdf(plan) {
    started.complete();
    return done.future;
  }
}

/// Forces a genuine collision at a fixed timestamp; the store must refuse it.
class ZeroRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

void main() {
  late FakeAuthService auth;
  late HeldMetadata repository;
  late FakeLocalReportStore store;
  late FakeReportViewer viewer;
  late FakeAnalytics analytics;
  late ProfileViewModel profile;

  ProfileViewModel wire({
    FakeReportService? report,
    FakeAnalytics? logger,
    FakeCrashlytics? diagnostics,
    Random? random,
    FakeStorageService? storage,
  }) {
    final vm = ProfileViewModel(
      authService: auth,
      metadataRepository: repository,
      storageService: storage,
      // No Storage adapter is necessary or constructed in the Final flow.
      notificationService: FakeNotificationService(),
      reportService: report ?? FakeReportService(),
      reportStore: store,
      reportViewer: viewer,
      remoteConfigService: FakeRemoteConfig(),
      crashlyticsService: diagnostics ?? FakeCrashlytics(),
      analyticsService: logger ?? analytics,
      now: () => DateTime.utc(2026, 11, 9, 12),
      random: random,
    );
    vm.onSessionStarted(testUser('uid-a'));
    addTearDown(vm.dispose);
    return vm;
  }

  Future<void> switchUser(String uid) async {
    profile.clearSession();
    auth.emitUid(uid);
    await auth.loadProfile(uid);
    profile.onSessionStarted(testUser(uid));
  }

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    auth = FakeAuthService(initialUid: 'uid-a');
    await auth.loadProfile('uid-a');
    repository = HeldMetadata();
    store = FakeLocalReportStore();
    viewer = FakeReportViewer();
    analytics = FakeAnalytics();
  });

  test(
    'default Final saves, opens, shares and logs without waiting for metadata',
    () async {
      profile = wire();
      await profile.exportPdf(planFor('uid-a'));
      expect(profile.exportState, isA<ViewStateSuccess<String>>());
      expect(profile.isExporting, isFalse);
      expect(profile.canRetryUpload, isFalse);
      expect(profile.uploadState, isA<ViewStateIdle<String>>());
      expect(profile.lastUploadedUrl, isNull);
      expect(profile.metadataState, ReportMetadataState.saving);
      expect(await profile.previewLastExport(), isTrue);
      expect(await profile.shareLastExport(), isTrue);
      expect(analytics.events, ['export_report:1:0']);
      final (uid, metadata, _) = repository.writes.single;
      expect(uid, 'uid-a');
      expect(metadata.toMap(), profile.lastExport!.metadata.toMap());
      expect(metadata.toMap().keys, orderedEquals(ReportMetadata.fields));
      expect(metadata.fileName, isNot(contains('uid-a')));
      expect(metadata.exportId, isNot(contains('plan-uid-a')));
      expect(metadata.createdAt, '2026-11-09T12:00:00.000Z');
    },
  );

  testWidgets(
    '15 seconds marks pending without cancelling or retrying the original write',
    (tester) async {
      profile = wire();
      await profile.exportPdf(planFor('uid-a'));
      await tester.pump(const Duration(seconds: 14));
      expect(profile.metadataState, ReportMetadataState.saving);
      await tester.pump(const Duration(seconds: 1));
      expect(profile.metadataState, ReportMetadataState.pending);
      profile.retryMetadata();
      expect(repository.writes, hasLength(1));
      expect(profile.canRetryMetadata, isFalse);
      expect(await profile.shareLastExport(), isTrue);
      repository.writes.single.$3.complete();
      await tester.pump();
      expect(profile.metadataState, ReportMetadataState.confirmed);
      expect(repository.writes, hasLength(1));
    },
  );

  test(
    'Final never calls a supplied Storage adapter, including retry/cancel',
    () async {
      final storage = CountingStorage();
      profile = wire(storage: storage);
      await profile.exportPdf(planFor('uid-a'));
      await profile.retryUpload();
      profile.cancelUpload();
      expect(storage.uploads, 0);
      expect(storage.cancelCalls, 0);
      expect(profile.canRetryUpload, isFalse);
    },
  );

  test('a failed generator produces no file, metadata or event', () async {
    final report = HeldReport();
    profile = wire(report: report);
    final result = profile.exportPdf(planFor('uid-a'));
    await report.started.future;
    report.done.completeError(StateError('PDF generation failed'));
    await result;
    expect(profile.exportState, isA<ViewStateError<String>>());
    expect(store.files, isEmpty);
    expect(repository.writes, isEmpty);
    expect(analytics.events, isEmpty);
  });

  test('a rejected write retries the exact payload, file and ID, with no new event', () async {
    profile = wire();
    await profile.exportPdf(planFor('uid-a'));
    final export = profile.lastExport!;
    final payload = repository.writes.single.$2.toMap();
    repository.writes.single.$3.completeError(StateError('denied'));
    await flush();
    expect(profile.metadataState, ReportMetadataState.error);
    expect(profile.canRetryMetadata, isTrue);
    expect(profile.exportState, isA<ViewStateSuccess<String>>());
    profile.retryMetadata();
    profile.retryMetadata();
    expect(repository.writes, hasLength(2));
    expect(repository.writes.last.$2.toMap(), payload);
    expect(profile.lastExport, same(export));
    expect(store.files, hasLength(1));
    repository.writes.last.$3.complete();
    await flush();
    expect(profile.metadataState, ReportMetadataState.confirmed);
    expect(analytics.events, ['export_report:1:0']);
  });

  for (final oldFails in [false, true]) {
    test(
      'a new export does not wait for metadata; stale ${oldFails ? 'failure' : 'ack'} cannot replace it',
      () async {
        profile = wire();
        await profile.exportPdf(planFor('uid-a'));
        final old = profile.lastExport!;
        await profile.exportPdf(planFor('uid-a').copyWith(id: 'second-plan'));
        final current = profile.lastExport!;
        expect(
          current.exportId,
          isNot(old.exportId),
          reason: 'same clock tick still gets a new ID',
        );
        expect(current.planId, 'second-plan');
        expect(repository.writes, hasLength(2));
        repository.writes.last.$3.complete();
        await flush();
        if (oldFails) {
          repository.writes.first.$3.completeError(StateError('old failure'));
        } else {
          repository.writes.first.$3.complete();
        }
        await flush();
        expect(profile.lastExport, same(current));
        expect(profile.metadataState, ReportMetadataState.confirmed);
        expect(profile.metadataError, isNull);
        expect(analytics.events, ['export_report:1:0', 'export_report:1:0']);
      },
    );
  }

  for (final next in ['uid-b', 'uid-a']) {
    for (final fails in [false, true]) {
      test(
        'metadata ${fails ? 'failure' : 'ack'} is ignored across A-logout-$next',
        () async {
          profile = wire();
          await profile.exportPdf(planFor('uid-a'));
          final old = repository.writes.single.$3;
          await switchUser(next);
          await profile.exportPdf(planFor(next));
          final current = profile.lastExport;
          if (fails) {
            old.completeError(StateError('old failure'));
          } else {
            old.complete();
          }
          await flush();
          expect(profile.lastExport, same(current));
          expect(profile.metadataState, ReportMetadataState.saving);
          expect(profile.metadataError, isNull);
          expect(repository.writes.last.$1, next);
          repository.writes.last.$3.complete();
          await flush();
          expect(profile.metadataState, ReportMetadataState.confirmed);
        },
      );
    }
  }

  testWidgets('old pending timer cannot change a new export', (tester) async {
    profile = wire();
    await profile.exportPdf(planFor('uid-a'));
    await tester.pump(const Duration(seconds: 10));
    await profile.exportPdf(planFor('uid-a'));
    await tester.pump(const Duration(seconds: 5));
    expect(profile.metadataState, ReportMetadataState.saving);
    await tester.pump(const Duration(seconds: 10));
    expect(profile.metadataState, ReportMetadataState.pending);
  });

  test(
    'a double tap during generation creates one PDF and one metadata write',
    () async {
      final report = HeldReport();
      profile = wire(report: report);
      final first = profile.exportPdf(planFor('uid-a'));
      await report.started.future;
      await profile.exportPdf(planFor('uid-a').copyWith(id: 'ignored-plan'));
      report.done.complete(Uint8List.fromList([1, 2, 3]));
      await first;
      expect(profile.lastExport!.planId, 'plan-uid-a');
      expect(repository.writes, hasLength(1));
      expect(store.files, hasLength(1));
      expect(analytics.events, ['export_report:1:0']);
    },
  );

  test(
    'a foreign plan is rejected before generation, save, metadata or event',
    () async {
      final report = HeldReport();
      profile = wire(report: report);
      await profile.exportPdf(planFor('uid-b'));
      expect(report.started.isCompleted, isFalse);
      expect(store.files, isEmpty);
      expect(repository.writes, isEmpty);
      expect(analytics.events, isEmpty);
    },
  );

  test(
    'an unsaved plan gets null planId without forcing a plan save',
    () async {
      profile = wire();
      await profile.exportPdf(planFor('uid-a').copyWith(id: ''));
      expect(repository.writes.single.$2.planId, isNull);
      expect(profile.lastExport!.planId, isNull);
    },
  );

  test('a failed save creates neither metadata nor export event', () async {
    profile = wire();
    store.saveError = const FileSystemException('disk full');
    await profile.exportPdf(planFor('uid-a'));
    expect(profile.exportState, isA<ViewStateError<String>>());
    expect(profile.lastExport, isNull);
    expect(repository.writes, isEmpty);
    expect(analytics.events, isEmpty);
  });

  test('a generation result from the previous session is ignored', () async {
    final report = HeldReport();
    profile = wire(report: report);
    final first = profile.exportPdf(planFor('uid-a'));
    await report.started.future;
    await switchUser('uid-a');
    report.done.complete(Uint8List.fromList([1, 2, 3]));
    await first;
    expect(profile.lastExport, isNull);
    expect(repository.writes, isEmpty);
    expect(analytics.events, isEmpty);
  });

  test('a slow/failing Analytics and broken Crashlytics cannot hold or fail a local save', () async {
    final logger = HeldAnalytics();
    profile = wire(logger: logger, diagnostics: BrokenDiagnostics());
    await profile.exportPdf(planFor('uid-a'));
    expect(profile.isExporting, isFalse);
    expect(await profile.shareLastExport(), isTrue);
    logger.done.completeError(StateError('analytics unavailable'));
    await flush();
    expect(profile.exportState, isA<ViewStateSuccess<String>>());
    expect(logger.events, ['export_report:1:0']);
  });

  test('late Analytics failure does not log under a new session', () async {
    final logger = HeldAnalytics();
    final diagnostics = FakeCrashlytics();
    profile = wire(logger: logger, diagnostics: diagnostics);
    await profile.exportPdf(planFor('uid-a'));
    await switchUser('uid-b');
    logger.done.completeError(StateError('old analytics failure'));
    await flush();
    expect(diagnostics.errors, isEmpty);
    expect(profile.exportState, isA<ViewStateIdle<String>>());
  });

  test('forced ID collision preserves the previous bytes, metadata and event count', () async {
    profile = wire(random: ZeroRandom());
    await profile.exportPdf(planFor('uid-a'));
    final export = profile.lastExport!;
    final before = List<int>.of(store.files.values.single);
    await profile.exportPdf(planFor('uid-a').copyWith(id: 'second-plan'));
    expect(profile.exportState, isA<ViewStateError<String>>());
    expect(profile.lastExport, same(export));
    expect(store.files.values.single, before);
    expect(repository.writes, hasLength(1));
    expect(analytics.events, ['export_report:1:0']);
  });

  test(
    'legacy filenames are neutral externally without renaming the local file',
    () {
      const old = ReportExport(
        exportId: 'uid-a_old-plan',
        planId: null,
        filePath: 'reports/uid-a/uid-a_old-plan.pdf',
        createdAt: '2026-11-09T12:00:00.000Z',
        sizeBytes: 3,
      );
      expect(old.externalFileName, 'Longvita-report.pdf');
      expect(old.filePath, 'reports/uid-a/uid-a_old-plan.pdf');
    },
  );

  test(
    'mode resolution fails closed for missing, unknown or remote settings',
    () {
      expect(resolvePdfExportMode(), PdfExportMode.finalLocal);
      for (final host in [
        '',
        'storage.googleapis.com',
        'localhost.evil',
        '192.168.1.1',
      ]) {
        expect(
          resolvePdfExportMode(
            mode: 'storage_emulator_demo',
            emulatorHost: host,
          ),
          PdfExportMode.finalLocal,
        );
      }
      for (final host in ['localhost', '127.0.0.1', '10.0.2.2']) {
        expect(
          resolvePdfExportMode(
            mode: 'storage_emulator_demo',
            emulatorHost: host,
          ),
          PdfExportMode.storageEmulatorDemo,
        );
        expect(
          resolvePdfExportMode(mode: 'unknown', emulatorHost: host),
          PdfExportMode.finalLocal,
        );
        expect(
          resolvePdfExportMode(mode: 'final', emulatorHost: host),
          PdfExportMode.finalLocal,
        );
      }
    },
  );

  test('concurrent colliding disk saves preserve the first file and queue stays usable', () async {
    final directory = await Directory.systemTemp.createTemp('nc03-collision-');
    addTearDown(() => directory.delete(recursive: true));
    final disk = LocalReportStore(baseDirectory: () async => directory);
    final first = disk.save(
      uid: 'uid-a',
      exportId: 'same',
      bytes: Uint8List.fromList([1]),
    );
    final second = disk.save(
      uid: 'uid-a',
      exportId: 'same',
      bytes: Uint8List.fromList([2]),
    );
    final rejection = expectLater(second, throwsA(isA<FileSystemException>()));
    await first;
    await rejection;
    expect(await disk.read(uid: 'uid-a', exportId: 'same'), [1]);
    await disk.save(
      uid: 'uid-a',
      exportId: 'next',
      bytes: Uint8List.fromList([3]),
    );
    expect(await disk.read(uid: 'uid-a', exportId: 'next'), [3]);
  });
  test('two independent stores cannot overwrite the same disk ID', () async {
    final directory = await Directory.systemTemp.createTemp('nc03-stores-');
    addTearDown(() => directory.delete(recursive: true));
    final a = LocalReportStore(baseDirectory: () async => directory);
    final b = LocalReportStore(baseDirectory: () async => directory);
    Future<int> save(LocalReportStore disk, int value) async {
      try {
        await disk.save(
          uid: 'uid-a',
          exportId: 'same',
          bytes: Uint8List.fromList([value]),
        );
        return value;
      } on FileSystemException {
        return 0;
      }
    }

    final results = await Future.wait([save(a, 1), save(b, 2)]);
    final winner = results.where((value) => value != 0).single;
    expect(await a.read(uid: 'uid-a', exportId: 'same'), [winner]);
    expect(
      Directory('${directory.path}/reports/uid-a').listSync(),
      hasLength(1),
    );
  });
}
