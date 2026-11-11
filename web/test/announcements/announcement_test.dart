import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_admin/admin/announcement_form.dart';
import 'package:longvita_admin/admin/announcement_viewmodel.dart';
import 'package:longvita_core/longvita_core.dart';
import 'package:provider/provider.dart';

class _Publisher implements IAnnouncementPublisher {
  final requests = <AnnouncementPublication>[];
  Future<void> Function()? action;
  bool Function()? sessionCheck;
  int ids = 0;

  @override
  String createId() => 'AbCdEf0123456789abc${++ids}';
  @override
  Future<void> publish(
    AnnouncementPublication publication, {
    required bool Function() sessionIsActive,
  }) async {
    publication.validate();
    requests.add(publication);
    sessionCheck = sessionIsActive;
    await action?.call();
  }
}

AnnouncementViewModel _model(
  _Publisher publisher, {
  bool Function()? active,
  Future<void> Function()? log,
}) => AnnouncementViewModel(
  publisher: publisher,
  uid: 'test-user',
  role: 'admin',
  sessionIsActive: active ?? () => true,
  trackSuccessfulPublish: log ?? () async {},
  now: () => DateTime.utc(2026, 11, 10, 12),
);

Widget host(AnnouncementViewModel vm, {double scale = 1}) => MaterialApp(
  theme: AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: ChangeNotifierProvider.value(
      value: vm,
      child: const AnnouncementForm(),
    ),
  ),
);

void main() {
  test('invalid input does not allocate an ID or send anything', () async {
    final publisher = _Publisher();
    final vm = _model(publisher);
    await vm.publish();
    expect(vm.titleError, isNotNull);
    expect(vm.contentError, isNotNull);
    expect(publisher.ids, 0);
    expect(publisher.requests, isEmpty);
    vm.dispose();
  });

  test(
    'retry reuses ID, payload and time; logs once after acknowledged success',
    () async {
      final publisher = _Publisher();
      var events = 0;
      final vm = _model(
        publisher,
        log: () async {
          events++;
        },
      );
      vm.changeTitle('  Tin kiểm thử  ');
      vm.changeContent('  Nội dung  ');
      publisher.action = () async =>
          throw const DataFailure(DataFailureKind.offline, 'Mất kết nối');
      await vm.publish();
      expect(vm.phase, AnnouncementPhase.failed);
      expect(events, 0);
      vm.changeTitle('Không được đổi payload khi retry');
      publisher.action = null;
      await vm.publish();
      await vm.publish();
      expect(publisher.ids, 1);
      expect(publisher.requests.length, 2);
      expect(
        identical(publisher.requests.first, publisher.requests.last),
        isTrue,
      );
      expect(publisher.requests.last.announcement.title, 'Tin kiểm thử');
      expect(publisher.requests.last.announcement.targetRoles, [
        'admin',
        'staff',
        'user',
      ]);
      expect(vm.published, isTrue);
      expect(events, 1);
      vm.startNew();
      expect(vm.editable, isTrue);
      expect(vm.title, isEmpty);
      vm.dispose();
    },
  );

  testWidgets(
    'deadline does not cancel, permit a duplicate, or claim success',
    (tester) async {
      final publisher = _Publisher();
      final pending = Completer<void>();
      publisher.action = () => pending.future;
      final vm = _model(publisher)
        ..changeTitle('Tin mới')
        ..changeContent('Nội dung');
      final first = vm.publish();
      await tester.pump(const Duration(seconds: 16));
      expect(vm.phase, AnnouncementPhase.awaitingConfirmation);
      await vm.publish();
      expect(publisher.requests.length, 1);
      expect(vm.published, isFalse);
      pending.complete();
      await first;
      expect(vm.published, isTrue);
      vm.dispose();
    },
  );

  test(
    'ended session blocks writes and ignores late success and telemetry',
    () async {
      final publisher = _Publisher();
      final pending = Completer<void>();
      publisher.action = () => pending.future;
      var active = true;
      var events = 0;
      final vm =
          _model(
              publisher,
              active: () => active,
              log: () async {
                events++;
              },
            )
            ..changeTitle('Tin mới')
            ..changeContent('Nội dung');
      final first = vm.publish();
      active = false;
      expect(publisher.sessionCheck!(), isFalse);
      pending.complete();
      await first;
      expect(vm.published, isFalse);
      expect(events, 0);
      await vm.publish();
      expect(publisher.requests.length, 1);
      vm.dispose();
    },
  );

  test(
    'telemetry failure never changes successful publication into an error',
    () async {
      final vm = _model(_Publisher(), log: () => throw StateError('telemetry'))
        ..changeTitle('Tin mới')
        ..changeContent('Nội dung');
      await vm.publish();
      await Future<void>.delayed(Duration.zero);
      expect(vm.published, isTrue);
      expect(vm.error, isNull);
      vm.dispose();
    },
  );

  testWidgets(
    'empty form validates; cancel does not send; confirmation sends once',
    (tester) async {
      final publisher = _Publisher();
      final vm = _model(publisher);
      await tester.pumpWidget(host(vm));
      final button = find.text('Phát thông báo');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập tiêu đề.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('announcement-title')),
        'Tin kiểm thử',
      );
      await tester.enterText(
        find.byKey(const ValueKey('announcement-content')),
        'Nội dung gửi đến Mobile.',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(publisher.requests, isEmpty);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đồng ý phát'));
      await tester.pumpAndSettle();
      expect(publisher.requests.length, 1);
      expect(find.textContaining('Đã phát thông báo.'), findsOneWidget);
      await tester.tap(find.text('Soạn thông báo mới'));
      await tester.pumpAndSettle();
      expect(vm.title, isEmpty);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('announcement-title')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );

  testWidgets('admin can target selected roles and must keep one selected', (
    tester,
  ) async {
    final publisher = _Publisher();
    final vm = _model(publisher);
    await tester.pumpWidget(host(vm));
    await tester.tap(find.byKey(const ValueKey('announcement-role-admin')));
    await tester.tap(find.byKey(const ValueKey('announcement-role-staff')));
    await tester.tap(find.byKey(const ValueKey('announcement-role-user')));
    await tester.enterText(
      find.byKey(const ValueKey('announcement-title')),
      'Tin theo vai trò',
    );
    await tester.enterText(
      find.byKey(const ValueKey('announcement-content')),
      'Nội dung',
    );
    await tester.ensureVisible(find.text('Phát thông báo'));
    await tester.tap(find.text('Phát thông báo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Vui lòng chọn ít nhất một nhóm người nhận.'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byKey(const ValueKey('announcement-role-staff')));
    await tester.tap(find.text('Phát thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đồng ý phát'));
    await tester.pumpAndSettle();
    expect(publisher.requests.single.announcement.targetRoles, ['staff']);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  for (final width in [360.0, 1280.0]) {
    testWidgets(
      'form at width $width, text 2.0 has reachable actions and no overflow',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final vm = _model(_Publisher());
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(host(vm, scale: 2));
        expect(tester.takeException(), isNull);
        final previewHeading = tester.getSemantics(
          find.text('Xem trước trên hộp thư'),
        );
        expect(previewHeading.label, 'Xem trước trên hộp thư');
        await tester.ensureVisible(find.text('Phát thông báo'));
        expect(find.text('Phát thông báo').hitTestable(), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
        vm.dispose();
      },
    );
  }
}
