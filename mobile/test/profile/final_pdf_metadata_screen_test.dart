import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/config/pdf_export_mode.dart';
import 'package:longvita_core/models/auth_state.dart';
import 'package:longvita_core/models/report_metadata.dart';
import 'package:longvita_core/services/i_report_metadata_repository.dart';
import 'package:longvita_core/services/i_report_service.dart';

import '../auth/auth_fakes.dart';
import '../auth/session_isolation_test.dart' show planFor;
import 'profile_screen_test.dart' show Harness;

class HeldMetadata implements IReportMetadataRepository {
  final writes = <(ReportMetadata, Completer<void>)>[];
  @override
  Future<void> save(String uid, ReportMetadata metadata) {
    final done = Completer<void>();
    writes.add((metadata, done));
    return done.future;
  }
}

class HeldReport extends FakeReportService {
  int calls = 0;
  final done = Completer<Uint8List>();
  @override
  Future<Uint8List> generateMealPlanPdf(plan) {
    calls++;
    return done.future;
  }
}

void main() {
  late HeldMetadata repository;
  late Harness h;

  Future<void> frames(WidgetTester tester) async {
    // Flush the completed Future, then render the frame it scheduled.
    await tester.pump();
    await tester.pump();
  }

  Future<void> finishWrites(WidgetTester tester) async {
    for (final write in repository.writes) {
      if (!write.$2.isCompleted) write.$2.complete();
    }
    await frames(tester);
  }

  Future<void> setup(
    WidgetTester tester, {
    double width = 360,
    double textScale = 1,
    IReportService? report,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository = HeldMetadata();
    h = Harness(
      exportMode: PdfExportMode.finalLocal,
      metadataRepository: repository,
      reportService: report,
    );
    addTearDown(h.profile.dispose);
    addTearDown(h.session.dispose);
    addTearDown(h.mealPlan.dispose);
    await tester.pumpWidget(h.app(textScale: textScale));
    await frames(tester);
    for (var i = 0; h.session.state is! AuthSignedOut && i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(h.session.state, isA<AuthSignedOut>());
    h.auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    unawaited(h.session.signInWithGoogle());
    for (var i = 0; h.profile.user == null && i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(h.profile.user?.uid, 'uid-a');
    h.mealPlan.selectSavedPlan(planFor('uid-a'));
    await frames(tester);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await frames(tester);
    await tester.tap(finder);
    await frames(tester);
  }

  Future<void> export(WidgetTester tester) async {
    await tap(tester, 'profile-export');
    await frames(tester);
    expect(h.profile.lastExport, isNotNull);
    expect(h.storage.uploads, 0);
    expect(find.text('Đã lưu PDF trên máy.'), findsOneWidget);
  }

  testWidgets(
    'Final sign-out warns that the local PDF has no app cloud backup',
    (tester) async {
      await setup(tester, textScale: 2);
      await tap(tester, 'profile-sign-out');
      expect(
        find.textContaining('PDF đã lưu trên máy này sẽ bị xóa.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Ứng dụng không lưu bản sao PDF trên đám mây.'),
        findsOneWidget,
      );
      expect(find.textContaining('Thực đơn đã lưu vẫn còn.'), findsOneWidget);
      expect(find.textContaining('Bản đã tải lên'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Hủy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất?'), findsNothing);
      expect(h.auth.signOutCalls, 0);
      expect(h.profile.user?.uid, 'uid-a');
    },
  );

  testWidgets(
    'saving, pending, confirmed are separate from the usable local file',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await setup(tester);
      await export(tester);
      const saving = 'Đang đồng bộ thông tin báo cáo…';
      expect(find.text(saving), findsOneWidget);
      expect(
        tester.getSemantics(find.text(saving)),
        isSemantics(label: saving, isLiveRegion: true),
      );
      await tester.pump(const Duration(seconds: 15));
      const pending =
          'Thông tin báo cáo đang chờ đồng bộ. Bạn vẫn có thể mở và chia sẻ PDF.';
      expect(find.text(pending), findsOneWidget);
      expect(find.byKey(const Key('profile-retry-metadata')), findsNothing);
      await tap(tester, 'profile-open');
      await tap(tester, 'profile-share');
      expect(h.viewer.previewed, hasLength(1));
      expect(h.viewer.shared, hasLength(1));
      expect(repository.writes, hasLength(1));
      repository.writes.single.$2.complete();
      await frames(tester);
      expect(find.text('Đã đồng bộ thông tin báo cáo.'), findsOneWidget);
      expect(find.text(pending), findsNothing);
      expect(find.byType(SelectableText), findsNothing);
      expect(find.byKey(const Key('profile-retry')), findsNothing);
      expect(find.byKey(const Key('profile-cancel-upload')), findsNothing);
      await finishWrites(tester);
      semantics.dispose();
    },
  );

  testWidgets(
    'metadata error retry is single-flight and reuses payload without hiding open/share',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await setup(tester);
      await export(tester);
      final first = repository.writes.single.$1.toMap();
      repository.writes.single.$2.completeError(
        StateError('private diagnostic'),
      );
      await frames(tester);
      const error = 'Chưa đồng bộ được thông tin báo cáo. PDF vẫn có trên máy.';
      expect(find.text(error), findsOneWidget);
      expect(find.textContaining('private diagnostic'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const Key('profile-retry-metadata')),
      );
      await frames(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Thử đồng bộ lại')),
        isSemantics(
          label: 'Thử đồng bộ lại',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
        ),
      );
      await tap(tester, 'profile-open');
      await tap(tester, 'profile-share');
      await tap(tester, 'profile-retry-metadata');
      expect(find.byKey(const Key('profile-retry-metadata')), findsNothing);
      h.profile.retryMetadata();
      expect(repository.writes, hasLength(2));
      expect(repository.writes.last.$1.toMap(), first);
      expect(h.analytics.events.where((e) => e.startsWith('export_report')), [
        'export_report:1:0',
      ]);
      repository.writes.last.$2.complete();
      await frames(tester);
      expect(find.text('Đã đồng bộ thông tin báo cáo.'), findsOneWidget);
      await finishWrites(tester);
      semantics.dispose();
    },
  );

  testWidgets(
    'a missing local file cannot be presented as an available cloud PDF',
    (tester) async {
      await setup(tester);
      await export(tester);
      repository.writes.single.$2.complete();
      await frames(tester);
      (h.profile.reportStore as FakeLocalReportStore).files.clear();
      await tap(tester, 'profile-open');
      expect(
        find.text('Không còn file PDF đã lưu trên máy. Vui lòng xuất lại.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profile-open')), findsNothing);
      expect(find.byKey(const Key('profile-share')), findsNothing);
      expect(find.text('Đã lưu PDF trên máy.'), findsNothing);
      expect(h.viewer.previewed, isEmpty);
      expect(
        repository.writes,
        hasLength(1),
        reason: 'cloud metadata is not deleted',
      );
    },
  );

  testWidgets(
    'Final generating button is disabled with no tap action, a second tap starts nothing',
    (tester) async {
      final semantics = tester.ensureSemantics();

      final report = HeldReport();
      await setup(tester, report: report);
      await tap(tester, 'profile-export');
      expect(find.text('Đang xuất PDF…'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Đang xuất PDF…')),
        isSemantics(isButton: true, isEnabled: false, hasTapAction: false),
      );
      await tester.tap(find.byKey(const Key('profile-export')));
      await frames(tester);
      expect(report.calls, 1);
      report.done.complete(Uint8List.fromList([1, 2, 3]));
      await frames(tester);
      expect(find.text('Đã lưu PDF trên máy.'), findsOneWidget);
      expect(find.byKey(const Key('profile-cancel-upload')), findsNothing);
      await finishWrites(tester);
      semantics.dispose();
    },
  );

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final fail in [false, true]) {
        testWidgets(
          'Final metadata ${fail ? 'error' : 'pending'} fits $width dp at text scale $scale',
          (tester) async {
            await setup(tester, width: width, textScale: scale);
            await export(tester);
            if (fail) {
              repository.writes.single.$2.completeError(
                StateError('unavailable'),
              );
              await frames(tester);
              await tap(tester, 'profile-retry-metadata');
            } else {
              await tester.pump(const Duration(seconds: 15));
            }
            await tap(tester, 'profile-share');
            expect(h.viewer.shared, hasLength(1));
            expect(tester.takeException(), isNull);
            expect(
              tester.getTopLeft(find.text('Báo cáo PDF')).dx,
              greaterThanOrEqualTo(0),
            );
            await finishWrites(tester);
          },
        );
      }
    }
  }
}
