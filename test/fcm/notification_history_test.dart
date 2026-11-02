// S4-12: the notification history stays on the device per user. Uses a fake
// gateway; delivery from Firebase is covered by evidence/fcm, not by this file.
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/notification_history_store.dart';
import 'package:longvita/firebase/notification_service.dart';
import 'package:longvita/models/app_notification.dart';

import 'notification_service_test.dart' show FakeGateway;

AppNotification note(String id, {String? recipient}) => AppNotification(
      messageId: id,
      title: 'Tiêu đề $id',
      body: 'Nội dung có dấu',
      recipientUid: recipient,
    );

RemoteMessage push(String id, {String? recipient}) => RemoteMessage(
      messageId: id,
      notification: RemoteNotification(title: 'Tiêu đề $id'),
      data: {'recipient_uid': ?recipient},
    );

void main() {
  late Directory dir;
  late NotificationHistoryStore store;

  List<String> ids(List<AppNotification> items) =>
      items.map((item) => item.messageId).toList();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('longvita_notifications');
    store = NotificationHistoryStore(baseDirectory: () async => dir);
  });

  tearDown(() => dir.delete(recursive: true));

  group('NotificationHistoryStore', () {
    test('keeps every field except the in-memory source', () async {
      const saved = AppNotification(
        messageId: 'm1',
        title: 'Thực đơn tuần này',
        body: 'Đã sẵn sàng',
        target: NotificationTarget('meal_plan', 'plan-1'),
        recipientUid: 'uid-a',
        source: 'not saved',
      );

      await store.save('uid-a', [saved]);
      final loaded = (await store.load('uid-a')).single;

      expect(loaded.messageId, 'm1');
      expect(loaded.title, 'Thực đơn tuần này');
      expect(loaded.body, 'Đã sẵn sàng');
      expect(loaded.target, saved.target);
      expect(loaded.recipientUid, 'uid-a');
      expect(loaded.source, isNull);
    });

    test('keeps the reason a target could not open', () async {
      await store.save('uid-a', [
        const AppNotification(
          messageId: 'm1',
          targetIssue: NotificationTargetIssue.unknownType,
        ),
      ]);

      expect((await store.load('uid-a')).single.targetIssue,
          NotificationTargetIssue.unknownType);
    });

    test('each user has their own file', () async {
      await store.save('uid-a', [note('a1')]);

      expect(await store.load('uid-b'), isEmpty);
    });

    test('keeps only the newest entries', () async {
      await store.save('uid-a', [
        for (var i = 0; i < NotificationHistoryStore.maxEntries + 5; i++)
          note('m$i'),
      ]);

      final loaded = await store.load('uid-a');
      expect(loaded, hasLength(NotificationHistoryStore.maxEntries));
      expect(loaded.first.messageId, 'm0');
    });

    for (final (name, content) in const [
      ('broken text', 'not json'),
      ('another shape', '{"a": 1}'),
      ('an entry with no id', '[{"title": "x"}]'),
    ]) {
      test('$name reads as an empty history', () async {
        await store.save('uid-a', [note('m1')]);
        await File('${dir.path}/notifications/uid-a.json').writeAsString(content);

        expect(await store.load('uid-a'), isEmpty);
      });
    }

    test('rejects a uid that could leave the folder or take the pending file',
        () async {
      await expectLater(store.load('../uid-a'), throwsArgumentError);
      await expectLater(store.save('pending', []), throwsArgumentError);
    });

    test('takePending returns the waiting messages once', () async {
      await store.addPending(note('p1'));
      await store.addPending(note('p2'));

      expect(ids(await store.takePending()), ['p2', 'p1']);
      expect(await store.takePending(), isEmpty);
    });
  });

  group('NotificationService history', () {
    late FakeGateway gateway;

    NotificationService newService() =>
        NotificationService(gateway: gateway, history: store);

    /// Lets a pushed message reach the service, then waits for its save.
    Future<void> settle(NotificationService service) async {
      await Future<void>.delayed(Duration.zero);
      await service.savesDone;
    }

    setUp(() => gateway = FakeGateway());

    test('a message comes back after the app restarts', () async {
      final first = newService();
      await first.bindUser('uid-a');
      await first.initialize();
      gateway.foreground.add(push('m1'));
      await settle(first);

      gateway = FakeGateway();
      final restarted = newService();
      await restarted.bindUser('uid-a');

      expect(ids(restarted.inbox), ['m1']);
    });

    test('the same user finds it after signing out and in', () async {
      final service = newService();
      await service.bindUser('uid-a');
      await service.initialize();
      gateway.foreground.add(push('m1'));
      await settle(service);

      service.clearHistory();
      expect(service.inbox, isEmpty);
      await service.bindUser('uid-a');

      expect(ids(service.inbox), ['m1']);
    });

    test('the next user never sees it', () async {
      final service = newService();
      await service.bindUser('uid-a');
      await service.initialize();
      gateway.foreground.add(push('m1'));
      await settle(service);

      service.clearHistory();
      await service.bindUser('uid-b');

      expect(service.inbox, isEmpty);
    });

    test('a redelivered message after a restart is not added twice', () async {
      await store.save('uid-a', [note('m1')]);
      final service = newService();
      await service.bindUser('uid-a');
      await service.initialize();

      gateway.foreground.add(push('m1'));
      await settle(service);

      expect(ids(service.inbox), ['m1']);
    });

    test('new messages stay above the restored ones', () async {
      await store.save('uid-a', [note('old')]);
      final service = newService();
      await service.bindUser('uid-a');
      await service.initialize();

      gateway.foreground.add(push('new'));
      await settle(service);

      expect(ids(service.inbox), ['new', 'old']);
    });

    test('background messages join the inbox at sign-in, oldest lowest', () async {
      await store.addPending(note('p1'));
      await store.addPending(note('p2'));
      final service = newService();

      await service.bindUser('uid-a');

      expect(ids(service.inbox), ['p2', 'p1']);
      expect(await store.takePending(), isEmpty);
    });

    test('a background message for another user is dropped', () async {
      await store.addPending(note('p1', recipient: 'uid-b'));
      final service = newService();

      await service.bindUser('uid-a');

      expect(service.inbox, isEmpty);
    });

    test('drainPending picks up a message while the app keeps running', () async {
      final service = newService();
      await service.bindUser('uid-a');
      var changes = 0;
      service.onChanged = () => changes++;

      await store.addPending(note('p1'));
      await service.drainPending();
      await settle(service);

      expect(ids(service.inbox), ['p1']);
      expect(changes, 1);
      expect(ids(await store.load('uid-a')), ['p1']);
    });

    test('drainPending with nobody signed in keeps the messages waiting', () async {
      await store.addPending(note('p1'));

      await newService().drainPending();

      expect(ids(await store.takePending()), ['p1']);
    });

    test('tapping a background message that already waits routes once', () async {
      const target = NotificationTarget('meal_plan', 'plan-1');
      await store.addPending(const AppNotification(messageId: 'm1', target: target));
      final service = newService();
      await service.bindUser('uid-a');
      await service.initialize();

      gateway.opened.add(const RemoteMessage(messageId: 'm1', data: {
        'schema_version': '1',
        'target_type': 'meal_plan',
        'target_id': 'plan-1',
      }));
      await settle(service);

      expect(ids(service.inbox), ['m1']);
      expect(service.takePendingTarget(), target);
      expect(service.takePendingTarget(), isNull);
    });

    test('the inbox still works when the files cannot be used', () async {
      final broken = NotificationHistoryStore(
          baseDirectory: () async => throw const FileSystemException('no disk'));
      final service = NotificationService(gateway: gateway, history: broken);

      await service.bindUser('uid-a');
      await service.initialize();
      gateway.foreground.add(push('m1'));
      await settle(service);

      expect(ids(service.inbox), ['m1']);
    });
  });
}
