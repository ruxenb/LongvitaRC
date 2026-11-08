// S4-12: the notification history stays on the device per user, and
// background messages wait in a per-message queue. Contract FCM v1: messages
// name their recipient (uid-a by default here). Uses a fake gateway and a real
// temporary folder; delivery from Firebase is covered by evidence/fcm.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/notification_history_store.dart';
import 'package:longvita/firebase/notification_service.dart';
import 'package:longvita/models/app_notification.dart';

import 'notification_service_test.dart' show FakeGateway;

AppNotification note(String id, {String? recipient = 'uid-a'}) => AppNotification(
      messageId: id,
      title: 'Tiêu đề $id',
      body: 'Nội dung có dấu',
      recipientUid: recipient,
    );

RemoteMessage push(String id, {String? recipient = 'uid-a'}) => RemoteMessage(
      messageId: id,
      notification: RemoteNotification(title: 'Tiêu đề $id'),
      data: {'recipient_uid': ?recipient},
    );

/// Lets a test hold one store call at a chosen point and release it later.
class Gate {
  final _entered = Completer<void>();
  final _released = Completer<void>();

  Future<void> get entered => _entered.future;

  void release() => _released.complete();

  Future<void> pass() {
    if (!_entered.isCompleted) _entered.complete();
    return _released.future;
  }
}

/// A real store on disk whose next load, claim or save can be held by a
/// [Gate] or fail once. A held load or claim has already read the disk, as
/// a slow read finishing late would have.
class GatedStore extends NotificationHistoryStore {
  Gate? loadGate, claimGate, saveGate;
  Object? loadError, saveError;

  GatedStore(Directory dir) : super(baseDirectory: () async => dir);

  @override
  Future<List<AppNotification>> load(String uid) async {
    final error = loadError;
    loadError = null;
    if (error != null) throw error;
    final items = await super.load(uid);
    final gate = loadGate;
    loadGate = null;
    if (gate != null) await gate.pass();
    return items;
  }

  @override
  Future<List<PendingNotification>> claimPending(String uid) async {
    final claimed = await super.claimPending(uid);
    final gate = claimGate;
    claimGate = null;
    if (gate != null) await gate.pass();
    return claimed;
  }

  @override
  Future<void> save(String uid, List<AppNotification> items) async {
    final gate = saveGate;
    saveGate = null;
    if (gate != null) await gate.pass();
    final error = saveError;
    saveError = null;
    if (error != null) throw error;
    return super.save(uid, items);
  }
}

void main() {
  late Directory dir;
  late NotificationHistoryStore store;

  List<String> ids(List<AppNotification> items) =>
      items.map((item) => item.messageId).toList();

  List<String> pendingIds(List<PendingNotification> items) =>
      items.map((item) => item.notification.messageId).toList();

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

    test('claimPending returns the waiting messages until they are acked',
        () async {
      await store.addPending(note('p1'));
      await store.addPending(note('p2'));

      final claimed = await store.claimPending('uid-a');
      expect(pendingIds(claimed), ['p1', 'p2']);
      expect(pendingIds(await store.claimPending('uid-a')), ['p1', 'p2']);

      await store.ackPending(claimed);
      expect(await store.claimPending('uid-a'), isEmpty);
      await store.ackPending(claimed); // a second ack is harmless
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
      expect(await store.claimPending('uid-a'), isEmpty);
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

      expect(pendingIds(await store.claimPending('uid-a')), ['p1']);
    });

    test('tapping a background message that already waits routes once', () async {
      const target = NotificationTarget('meal_plan', 'plan-1');
      await store.addPending(const AppNotification(
          messageId: 'm1', target: target, recipientUid: 'uid-a'));
      final service = newService();
      await service.bindUser('uid-a');
      await service.initialize();

      gateway.opened.add(const RemoteMessage(messageId: 'm1', data: {
        'schema_version': '1',
        'target_type': 'meal_plan',
        'target_id': 'plan-1',
        'recipient_uid': 'uid-a',
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

  group('queue on disk', () {
    test('a message with no recipient is not queued', () async {
      await store.addPending(note('x', recipient: null));
      expect(await store.claimPending('uid-a'), isEmpty);
      expect(Directory('${dir.path}/notifications/pending').existsSync(), isFalse);
    });

    test('each user claims only their own messages', () async {
      await store.addPending(note('a1'));
      await store.addPending(note('b1', recipient: 'uid-b'));
      await store.addPending(note('a2'));

      final forA = await store.claimPending('uid-a');
      await store.ackPending(forA);

      expect(pendingIds(forA), ['a1', 'a2']);
      expect(pendingIds(await store.claimPending('uid-b')), ['b1']);
    });

    test('a message added by another writer during a claim is kept', () async {
      // A second store on the same folder stands for the background isolate.
      final background = NotificationHistoryStore(baseDirectory: () async => dir);
      await store.addPending(note('p1'));

      final claimed = await store.claimPending('uid-a');
      await background.addPending(note('p2'));
      await store.ackPending(claimed);

      expect(pendingIds(await store.claimPending('uid-a')), ['p2']);
    });

    test('keeps at most maxPending messages, the newest', () async {
      const extra = 3;
      for (var i = 0; i < NotificationHistoryStore.maxPending + extra; i++) {
        await store.addPending(note('p$i'));
      }

      final claimed = pendingIds(await store.claimPending('uid-a'));
      expect(claimed, hasLength(NotificationHistoryStore.maxPending));
      expect(claimed.first, 'p$extra');
    });

    test('a broken, misnamed or half-written file is skipped', () async {
      await store.addPending(note('p1'));
      final queue = '${dir.path}/notifications/pending';
      File('$queue/0000000000000001-deadbeef.json').writeAsStringSync('not json');
      File('$queue/0000000000000002-deadbeef.json').writeAsStringSync('{"title": 1}');
      File('$queue/evil.json')
          .writeAsStringSync(jsonEncode(note('evil').toJson()));
      File('$queue/0000000000000003-deadbeef.json.tmp')
          .writeAsStringSync(jsonEncode(note('half').toJson()));

      expect(pendingIds(await store.claimPending('uid-a')), ['p1']);
    });

    test('an unsafe uid or ref is refused', () async {
      await store.save('uid-a', [note('m1')]);
      await expectLater(store.claimPending('../uid-a'), throwsArgumentError);
      await expectLater(store.claimPending('pending'), throwsArgumentError);

      await store.ackPending([PendingNotification(note('m1'), '../uid-a.json')]);

      expect(ids(await store.load('uid-a')), ['m1']);
    });

    test('the queue file of the earlier version moves per recipient', () async {
      final legacy = File('${dir.path}/notifications/pending.json')
        ..parent.createSync(recursive: true)
        // Newest first, as the earlier version wrote it.
        ..writeAsStringSync(jsonEncode([
          note('a-new').toJson(),
          note('b1', recipient: 'uid-b').toJson(),
          note('nobody', recipient: null).toJson(),
          note('a-old').toJson(),
        ]));

      expect(pendingIds(await store.claimPending('uid-a')), ['a-old', 'a-new']);
      expect(legacy.existsSync(), isFalse);
      expect(pendingIds(await store.claimPending('uid-b')), ['b1']);
      expect(Directory('${dir.path}/notifications/pending').listSync(),
          hasLength(3));
    });

    test('a history entry that cannot be read costs only itself', () async {
      File('${dir.path}/notifications/uid-a.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(jsonEncode([
          note('a1').toJson(),
          {'message_id': 5},
          'junk',
          {'message_id': 'a2', 'title': 7},
          note('a3').toJson(),
        ]));

      expect(ids(await store.load('uid-a')), ['a1', 'a3']);
    });
  });

  group('NotificationService sessions and persistence', () {
    late FakeGateway gateway;
    late GatedStore gated;

    NotificationService newService() =>
        NotificationService(gateway: gateway, history: gated);

    Future<void> settle(NotificationService service) async {
      await Future<void>.delayed(Duration.zero);
      await service.savesDone;
    }

    setUp(() {
      gateway = FakeGateway();
      gated = GatedStore(dir);
    });

    test('history of A, B and no recipient: A sees only A, valid entries stay',
        () async {
      File('${dir.path}/notifications/uid-a.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(jsonEncode([
          note('a1').toJson(),
          note('b1', recipient: 'uid-b').toJson(),
          note('legacy', recipient: null).toJson(),
          note('a2').toJson(),
        ]));
      final service = newService();
      await service.bindUser('uid-a');
      expect(ids(service.inbox), ['a1', 'a2']);

      await service.initialize();
      gateway.foreground.add(push('new'));
      await settle(service);

      expect(ids(await store.load('uid-a')), ['new', 'a1', 'a2']);
    });

    test('A -> logout -> A while the first load waits: it restores nothing',
        () async {
      await store.save('uid-a', [note('stale')]);
      gated.loadGate = Gate();
      final service = newService();
      var changes = 0;
      service.onChanged = () => changes++;

      final gate = gated.loadGate!;
      final first = service.bindUser('uid-a');
      await gate.entered;
      service.clearHistory();
      await store.save('uid-a', [note('fresh')]);
      await service.bindUser('uid-a');
      final changesOfSecond = changes;

      gate.release();
      await first;
      await settle(service);

      expect(ids(service.inbox), ['fresh']);
      expect(ids(await store.load('uid-a')), ['fresh']);
      expect(changes, changesOfSecond);
    });

    test("A -> B while A's history loads: B gets nothing of A", () async {
      await store.save('uid-a', [note('a1')]);
      gated.loadGate = Gate();
      final service = newService();

      final gate = gated.loadGate!;
      final first = service.bindUser('uid-a');
      await gate.entered;
      await service.bindUser('uid-b');
      gate.release();
      await first;
      await settle(service);

      expect(service.inbox, isEmpty);
      expect(await store.load('uid-b'), isEmpty);
    });

    test("A -> logout -> B while A drains: A's messages stay queued for A",
        () async {
      await store.save('uid-a', [note('ha')]);
      await store.addPending(note('pa'));
      gated.claimGate = Gate();
      final service = newService();

      final gate = gated.claimGate!;
      final first = service.bindUser('uid-a');
      await gate.entered;
      service.clearHistory();
      await service.bindUser('uid-b');
      gate.release();
      await first;
      await settle(service);

      expect(service.inbox, isEmpty);
      expect(await store.load('uid-b'), isEmpty);
      // The old drain saved nothing of B into A's file, nor emptied it.
      expect(ids(await store.load('uid-a')), ['ha']);
      expect(pendingIds(await store.claimPending('uid-a')), ['pa']);
    });

    test("sign-out during a drain neither empties A's history nor drops it",
        () async {
      await store.save('uid-a', [note('ha')]);
      final service = newService();
      await service.bindUser('uid-a');
      await store.addPending(note('pa'));
      gated.claimGate = Gate();

      final gate = gated.claimGate!;
      final drain = service.drainPending();
      await gate.entered;
      service.clearHistory();
      gate.release();
      await drain;
      await settle(service);

      expect(ids(await store.load('uid-a')), ['ha']);
      expect(pendingIds(await store.claimPending('uid-a')), ['pa']);

      await service.bindUser('uid-a');
      expect(ids(service.inbox), ['pa', 'ha']);
    });

    test('messages added in the background during a drain are not lost',
        () async {
      final background = NotificationHistoryStore(baseDirectory: () async => dir);
      await store.addPending(note('p1'));
      gated.saveGate = Gate();
      final service = newService();

      final gate = gated.saveGate!;
      final bind = service.bindUser('uid-a');
      await gate.entered;
      await background.addPending(note('p2'));
      await background.addPending(note('b1', recipient: 'uid-b'));
      gate.release();
      await bind;

      expect(ids(await store.load('uid-a')), ['p1']);
      expect(pendingIds(await store.claimPending('uid-a')), ['p2']);
      expect(pendingIds(await store.claimPending('uid-b')), ['b1']);

      await service.drainPending();
      expect(ids(service.inbox), ['p2', 'p1']);
    });

    test('a failed save keeps the messages queued; the retry adds no duplicate',
        () async {
      await store.addPending(note('p1'));
      gated.saveError = const FileSystemException('disk full');
      final service = newService();

      await service.bindUser('uid-a');
      expect(ids(service.inbox), ['p1']);
      expect(pendingIds(await store.claimPending('uid-a')), ['p1']);

      await service.drainPending();

      expect(ids(service.inbox), ['p1']);
      expect(await store.claimPending('uid-a'), isEmpty);
      expect(ids(await store.load('uid-a')), ['p1']);
    });

    test('history that could not be read is never overwritten', () async {
      await store.save('uid-a', [note('old')]);
      await store.addPending(note('p1'));
      gated.loadError = const FileSystemException('busy');
      final service = newService();

      await service.bindUser('uid-a');
      await service.initialize();
      gateway.foreground.add(push('new'));
      await settle(service);

      expect(ids(service.inbox), ['new', 'p1']);
      expect(ids(await store.load('uid-a')), ['old']);
      expect(pendingIds(await store.claimPending('uid-a')), ['p1']);
    });

    test('a tap arriving while the history loads is saved with it, opened once',
        () async {
      await store.save('uid-a', [note('old')]);
      gated.loadGate = Gate();
      final service = newService();

      final gate = gated.loadGate!;
      final bind = service.bindUser('uid-a');
      await gate.entered;
      await service.initialize();
      gateway.opened.add(push('tap'));
      await Future<void>.delayed(Duration.zero);
      expect(ids(await store.load('uid-a')), ['old']);

      gate.release();
      await bind;
      await settle(service);

      expect(ids(service.inbox), ['tap', 'old']);
      expect(ids(await store.load('uid-a')), ['tap', 'old']);
      expect(service.takeOpenRequest(), isTrue);
      expect(service.takeOpenRequest(), isFalse);
    });

    test("sign-out keeps A's saved history and drops what is on screen",
        () async {
      final service = newService();
      await service.bindUser('uid-a');
      await service.initialize();
      gateway.foreground.add(push('m1'));
      await settle(service);

      service.clearHistory();

      expect(service.inbox, isEmpty);
      expect(service.takeArrival(), isNull);
      expect(service.takeOpenRequest(), isFalse);
      expect(ids(await store.load('uid-a')), ['m1']);
    });
  });
}
