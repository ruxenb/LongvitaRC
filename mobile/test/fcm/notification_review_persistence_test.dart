// PR19-CR-02/03/04: real-file regressions for durability and resumable migration.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/notification_history_store.dart';
import 'package:longvita/firebase/notification_service.dart';
import 'package:longvita_core/models/app_notification.dart';

AppNotification note(String id, [String uid = 'uid-a']) =>
    AppNotification(messageId: id, recipientUid: uid);

class Gateway implements FcmGateway {
  final foreground = StreamController<RemoteMessage>.broadcast(sync: true);
  final opened = StreamController<RemoteMessage>.broadcast(sync: true);
  @override
  Future<bool> requestPermission() async => true;
  @override
  Stream<RemoteMessage> get onMessage => foreground.stream;
  @override
  Stream<RemoteMessage> get onMessageOpenedApp => opened.stream;
  @override
  Future<RemoteMessage?> getInitialMessage() async => null;
  @override
  void registerBackgroundHandler() {}
  @override
  Future<String?> getToken() async => null;
  Future<void> close() async {
    await foreground.close();
    await opened.close();
  }
}

void main() {
  late Directory dir;
  late NotificationHistoryStore store;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pm_pr19_');
    store = NotificationHistoryStore(baseDirectory: () async => dir);
  });
  tearDown(() => dir.delete(recursive: true));
  test(
    'CR02: foreground survives logout before unreadable history recovers',
    () async {
      await store.save('uid-a', [note('old')]);
      var blocked = true;
      final failing = NotificationHistoryStore(
        baseDirectory: () async => dir,
        readFile: (file) {
          if (blocked && file.path.endsWith('uid-a.json')) {
            throw FileSystemException('read blocked', file.path);
          }
          return file.readAsString();
        },
      );
      final gateway = Gateway();
      addTearDown(gateway.close);
      final service = NotificationService(gateway: gateway, history: failing);
      await service.bindUser('uid-a');
      await service.initialize();
      gateway.foreground.add(
        const RemoteMessage(
          messageId: 'foreground-new',
          data: {'recipient_uid': 'uid-a'},
        ),
      );
      await service.savesDone;
      service.clearHistory();
      blocked = false;
      final fresh = NotificationService(gateway: gateway, history: store);
      await fresh.bindUser('uid-a');
      expect(
        fresh.inbox.map((n) => n.messageId),
        containsAll(['foreground-new', 'old']),
      );
    },
  );
  test(
    'CR03: legacy migration cannot evict newer pending at capacity',
    () async {
      for (var i = 0; i < 50; i++) {
        await store.addPending(note('new-$i', 'uid-b'));
      }
      final legacy = File('${dir.path}/notifications/pending.json');
      await legacy.writeAsString(
        jsonEncode([for (var i = 4; i >= 0; i--) note('legacy-$i').toJson()]),
      );
      await store.claimPending('uid-a');
      final b = await store.claimPending('uid-b');
      expect(
        b.map((n) => n.notification.messageId),
        containsAll([for (var i = 0; i < 50; i++) 'new-$i']),
      );
      expect(b, hasLength(50));
    },
  );
  test(
    'CR04: interrupted legacy migration resumes without duplicates',
    () async {
      final legacy = File('${dir.path}/notifications/pending.json');
      await legacy.parent.create(recursive: true);
      await legacy.writeAsString(
        jsonEncode([note('old-2').toJson(), note('old-1').toJson()]),
      );
      var interrupted = false;
      final interrupting = NotificationHistoryStore(
        baseDirectory: () async {
          final pending = Directory('${dir.path}/notifications/pending');
          if (!interrupted &&
              pending.existsSync() &&
              pending.listSync().any((f) => f.path.endsWith('.json'))) {
            interrupted = true;
            throw const FileSystemException(
              'simulate interruption after queue write',
            );
          }
          return dir;
        },
      );
      await expectLater(
        interrupting.claimPending('uid-a'),
        throwsA(isA<FileSystemException>()),
      );
      expect(interrupted, isTrue);
      final recovered = await store.claimPending('uid-a');
      expect(recovered.map((e) => e.notification.messageId), [
        'old-1',
        'old-2',
      ]);
      expect(await legacy.exists(), isFalse);
    },
  );

  test('concurrent stores migrate once and keep recipient order', () async {
    final legacy = File('${dir.path}/notifications/pending.json');
    await legacy.parent.create(recursive: true);
    await legacy.writeAsString(
      jsonEncode([
        note('a-new').toJson(),
        note('b-old', 'uid-b').toJson(),
        note('a-old').toJson(),
      ]),
    );
    final other = NotificationHistoryStore(baseDirectory: () async => dir);
    final results = await Future.wait([
      store.claimPending('uid-a'),
      other.claimPending('uid-b'),
      other.claimPending('uid-a'),
    ]);
    expect(results[0].map((e) => e.notification.messageId), ['a-old', 'a-new']);
    expect(results[1].map((e) => e.notification.messageId), ['b-old']);
    expect(results[2].map((e) => e.ref), results[0].map((e) => e.ref));
    await store.ackPending(results[0]);
    expect(await store.claimPending('uid-a'), isEmpty);
    expect(
      (await store.claimPending('uid-b')).single.notification.messageId,
      'b-old',
    );
  });
  test(
    'unreadable checkpoint keeps legacy and existing pending intact',
    () async {
      await store.addPending(note('new-b', 'uid-b'));
      final legacy = File('${dir.path}/notifications/pending.json');
      await legacy.writeAsString(jsonEncode([note('legacy-a').toJson()]));
      final failing = NotificationHistoryStore(
        baseDirectory: () async => dir,
        readFile: (file) {
          if (file.path.endsWith('pending.migration.json')) {
            throw const FileSystemException(
              'checkpoint temporarily unreadable',
            );
          }
          return file.readAsString();
        },
      );
      await expectLater(
        failing.claimPending('uid-a'),
        throwsA(isA<FileSystemException>()),
      );
      expect(await legacy.exists(), isTrue);
      final a = await store.claimPending('uid-a');
      expect(a.single.notification.messageId, 'legacy-a');
      expect(
        (await store.claimPending('uid-b')).single.notification.messageId,
        'new-b',
      );
      expect(
        await File('${dir.path}/notifications/pending.migration.json').exists(),
        isFalse,
      );
    },
  );
}
