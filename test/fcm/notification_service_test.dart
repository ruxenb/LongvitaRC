// S4-12 preparation: payload parsing, dedup, per-user inbox and lifecycle
// wiring against a fake gateway. Live delivery on a device is not covered.
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/notification_inbox.dart';
import 'package:longvita/firebase/notification_service.dart';
import 'package:longvita/models/app_notification.dart';

const planTarget = NotificationTarget('meal_plan', 'plan-1');

Map<String, dynamic> payload({
  String id = 'm1',
  String? recipient,
  String type = 'meal_plan',
  String targetId = 'plan-1',
}) =>
    {
      'schema_version': '1',
      'message_id': id,
      'target_type': type,
      'target_id': targetId,
      'recipient_uid': ?recipient,
    };

AppNotification note({String id = 'm1', String? recipient}) =>
    AppNotification.parse(data: payload(id: id, recipient: recipient))!;

class FakeGateway implements FcmGateway {
  final foreground = StreamController<RemoteMessage>.broadcast();
  final opened = StreamController<RemoteMessage>.broadcast();
  RemoteMessage? initial;
  bool grant = true;
  Object? permissionError;
  int permissionCalls = 0;
  int backgroundRegistrations = 0;

  @override
  Future<bool> requestPermission() async {
    permissionCalls++;
    if (permissionError != null) throw permissionError!;
    return grant;
  }

  @override
  Stream<RemoteMessage> get onMessage => foreground.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => opened.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initial;

  @override
  void registerBackgroundHandler() => backgroundRegistrations++;

  @override
  Future<String?> getToken() async => 'token';
}

void main() {
  group('AppNotification.parse', () {
    test('reads a valid target', () {
      final parsed = AppNotification.parse(data: payload());
      expect(parsed?.target, planTarget);
      expect(parsed?.targetIssue, NotificationTargetIssue.none);
    });

    test('falls back to the FCM id, and rejects a message with no id', () {
      expect(AppNotification.parse(data: const {}, fcmMessageId: 'f1')?.messageId,
          'f1');
      expect(AppNotification.parse(data: const {}), isNull);
    });

    test('never trusts a route string from the payload', () {
      final parsed = AppNotification.parse(data: {
        'message_id': 'm1',
        'route': '/admin/secret',
        'screen': 'AdminScreen',
      });
      expect(parsed?.target, isNull);
      expect(parsed?.targetIssue, NotificationTargetIssue.none);
    });

    test('keeps a bad target in the inbox with the reason', () {
      expect(AppNotification.parse(data: payload(type: 'admin_panel'))?.targetIssue,
          NotificationTargetIssue.unknownType);
      expect(AppNotification.parse(data: payload(targetId: ' '))?.targetIssue,
          NotificationTargetIssue.missingId);
      expect(
          AppNotification.parse(data: {...payload(), 'schema_version': '9'})
              ?.targetIssue,
          NotificationTargetIssue.unsupportedVersion);
    });
  });

  group('NotificationInbox', () {
    test('one message through several callbacks: one entry, one route', () {
      final inbox = NotificationInbox()..bind('uid-a');

      expect(inbox.receive(note()), isTrue);
      expect(inbox.receive(note(), tapped: true), isFalse);
      expect(inbox.receive(note(), tapped: true), isFalse);

      expect(inbox.items, hasLength(1));
      expect(inbox.takePendingTarget(), planTarget);
      expect(inbox.takePendingTarget(), isNull);
    });

    test('a message for another recipient is dropped', () {
      final inbox = NotificationInbox()..bind('uid-b');

      inbox.receive(note(recipient: 'uid-a'), tapped: true);

      expect(inbox.items, isEmpty);
      expect(inbox.takePendingTarget(), isNull);
    });

    test('A -> logout -> B: nothing of A remains', () {
      final inbox = NotificationInbox()..bind('uid-a');
      inbox.receive(note(), tapped: true);

      inbox.clear();
      inbox.bind('uid-b');

      expect(inbox.items, isEmpty);
      expect(inbox.takePendingTarget(), isNull);
    });

    test('a late callback for A while signed out does not reach B', () {
      final inbox = NotificationInbox()..bind('uid-a');
      inbox.clear();

      inbox.receive(note(recipient: 'uid-a'));
      inbox.bind('uid-b');

      expect(inbox.items, isEmpty);
    });

    test('sign-out drops messages waiting for a sign-in', () {
      final inbox = NotificationInbox();
      inbox.receive(note(), tapped: true);

      inbox.clear();
      inbox.bind('uid-a');

      expect(inbox.items, isEmpty);
      expect(inbox.takePendingTarget(), isNull);
    });

    test('a tap before sign-in waits for the session (cold start)', () {
      final inbox = NotificationInbox();

      inbox.receive(note(recipient: 'uid-a'), tapped: true);
      expect(inbox.takePendingTarget(), isNull);

      inbox.bind('uid-a');
      expect(inbox.items, hasLength(1));
      expect(inbox.takePendingTarget(), planTarget);
    });

    test('a tapped message with a bad target gives no route', () {
      final inbox = NotificationInbox()..bind('uid-a');

      inbox.receive(AppNotification.parse(data: payload(type: 'admin_panel'))!,
          tapped: true);

      expect(inbox.items, hasLength(1));
      expect(inbox.takePendingTarget(), isNull);
    });

    test('rebinding the same user keeps the inbox', () {
      final inbox = NotificationInbox()..bind('uid-a');
      inbox.receive(note());

      inbox.bind('uid-a');

      expect(inbox.items, hasLength(1));
    });
  });

  group('NotificationService', () {
    late FakeGateway gateway;
    late NotificationService service;

    RemoteMessage message({String id = 'm1'}) =>
        RemoteMessage(messageId: id, data: payload(id: id));

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    setUp(() {
      gateway = FakeGateway();
      service = NotificationService(gateway: gateway);
    });

    test('initializes once, including the background handler', () async {
      await service.initialize();
      await service.initialize();

      expect(gateway.permissionCalls, 1);
      expect(gateway.backgroundRegistrations, 1);
      expect(service.permission, NotificationPermission.granted);
    });

    test('foreground, opened and initial all reach one inbox', () async {
      service.bindUser('uid-a');
      gateway.initial = message(id: 'initial');
      await service.initialize();

      gateway.foreground.add(message(id: 'fg'));
      gateway.opened.add(message(id: 'tap'));
      await settle();

      expect(service.inbox.map((n) => n.messageId), ['tap', 'fg', 'initial']);
      expect(service.messages, hasLength(3));
    });

    test('foreground then tap of one message is deduplicated', () async {
      service.bindUser('uid-a');
      await service.initialize();

      gateway.foreground.add(message());
      gateway.opened.add(message());
      await settle();

      expect(service.inbox, hasLength(1));
      expect(service.takePendingTarget(), planTarget);
    });

    test('a denied permission still receives a tap, with no crash', () async {
      gateway.grant = false;
      service.bindUser('uid-a');
      await service.initialize();

      gateway.opened.add(message());
      await settle();

      expect(service.permission, NotificationPermission.denied);
      expect(service.inbox, hasLength(1));
    });

    test('a failed start is reported, not thrown', () async {
      gateway.permissionError = Exception('no play services');

      await service.initialize();

      expect(service.permission, NotificationPermission.failed);
    });

    test('sign-out clears the inbox and the raw messages', () async {
      service.bindUser('uid-a');
      await service.initialize();
      gateway.foreground.add(message());
      await settle();

      service.clearHistory();

      expect(service.inbox, isEmpty);
      expect(service.messages, isEmpty);
    });

    group('PM-FCM-01: raw and typed state follow one decision', () {
      RemoteMessage shared({
        required String fcmId,
        required String recipient,
        required String title,
        String targetId = 'plan-1',
      }) =>
          RemoteMessage(
            messageId: fcmId,
            notification: RemoteNotification(title: title),
            data: payload(
                id: 'shared-id', recipient: recipient, targetId: targetId),
          );

      /// `inbox` and `messages` must describe the same accepted messages.
      void expectAgree(NotificationService service, String recipient, String title) {
        expect(service.inbox.single.recipientUid, recipient);
        expect(service.inbox.single.title, title);
        final raw = service.messages.single;
        expect(raw.data['recipient_uid'], recipient);
        expect(raw.notification?.title, title);
      }

      test('a late message for A does not overwrite B', () async {
        service.bindUser('uid-b');
        await service.initialize();

        gateway.foreground
            .add(shared(fcmId: 'fcm-b', recipient: 'uid-b', title: 'Tin của B'));
        gateway.foreground
            .add(shared(fcmId: 'fcm-a', recipient: 'uid-a', title: 'Tin của A'));
        await settle();

        expectAgree(service, 'uid-b', 'Tin của B');
      });

      test('a rejected message first does not block the accepted one', () async {
        service.bindUser('uid-b');
        await service.initialize();

        gateway.foreground
            .add(shared(fcmId: 'fcm-a', recipient: 'uid-a', title: 'Tin của A'));
        await settle();
        expect(service.messages, isEmpty);

        gateway.foreground
            .add(shared(fcmId: 'fcm-b', recipient: 'uid-b', title: 'Tin của B'));
        await settle();

        expectAgree(service, 'uid-b', 'Tin của B');
      });

      test('a duplicate with other content keeps the first accepted', () async {
        service.bindUser('uid-b');
        await service.initialize();

        gateway.foreground
            .add(shared(fcmId: 'first', recipient: 'uid-b', title: 'Bản đầu'));
        gateway.foreground
            .add(shared(fcmId: 'second', recipient: 'uid-b', title: 'Bản sau'));
        await settle();

        expectAgree(service, 'uid-b', 'Bản đầu');
      });

      test('a tapped duplicate routes to the accepted target', () async {
        service.bindUser('uid-b');
        await service.initialize();

        gateway.foreground.add(shared(
            fcmId: 'first', recipient: 'uid-b', title: 'Bản đầu', targetId: 'plan-b'));
        gateway.opened.add(shared(
            fcmId: 'second', recipient: 'uid-b', title: 'Bản sau', targetId: 'other'));
        await settle();

        expect(service.takePendingTarget(),
            const NotificationTarget('meal_plan', 'plan-b'));
      });

      test('a tapped message for A gives B no route', () async {
        service.bindUser('uid-b');
        await service.initialize();

        gateway.opened
            .add(shared(fcmId: 'fcm-a', recipient: 'uid-a', title: 'Tin của A'));
        await settle();

        expect(service.inbox, isEmpty);
        expect(service.messages, isEmpty);
        expect(service.takePendingTarget(), isNull);
      });

      test('held messages keep their payload until sign-in', () async {
        await service.initialize();

        gateway.foreground
            .add(shared(fcmId: 'fcm-a', recipient: 'uid-a', title: 'Tin của A'));
        gateway.foreground
            .add(shared(fcmId: 'fcm-b', recipient: 'uid-b', title: 'Tin của B'));
        await settle();
        expect(service.messages, isEmpty);

        service.bindUser('uid-b');

        expectAgree(service, 'uid-b', 'Tin của B');
      });

      test('a held message for A arriving last does not overwrite B', () async {
        await service.initialize();

        gateway.foreground
            .add(shared(fcmId: 'fcm-b', recipient: 'uid-b', title: 'Tin của B'));
        gateway.foreground
            .add(shared(fcmId: 'fcm-a', recipient: 'uid-a', title: 'Tin của A'));
        await settle();

        service.bindUser('uid-b');

        expectAgree(service, 'uid-b', 'Tin của B');
      });

      test('a held tap keeps its payload and routes after sign-in', () async {
        gateway.initial = message(id: 'cold');
        await service.initialize();

        service.bindUser('uid-a');

        expect(service.messages.single.messageId, 'cold');
        expect(service.takePendingTarget(), planTarget);
      });

      test('foreground then tap keeps one payload and still routes', () async {
        service.bindUser('uid-a');
        await service.initialize();

        gateway.foreground.add(message());
        gateway.opened.add(message());
        await settle();

        expect(service.messages, hasLength(1));
        expect(service.takePendingTarget(), planTarget);
      });

      test('A -> logout -> B: no payload of A remains', () async {
        service.bindUser('uid-a');
        await service.initialize();
        gateway.foreground
            .add(shared(fcmId: 'fcm-a', recipient: 'uid-a', title: 'Tin của A'));
        await settle();

        service.clearHistory();
        service.bindUser('uid-b');
        gateway.foreground
            .add(shared(fcmId: 'fcm-a2', recipient: 'uid-a', title: 'Tin của A'));
        await settle();

        expect(service.inbox, isEmpty);
        expect(service.messages, isEmpty);
      });

      test('binding B directly over A drops the payload of A', () async {
        service.bindUser('uid-a');
        await service.initialize();
        gateway.foreground
            .add(shared(fcmId: 'fcm-a', recipient: 'uid-a', title: 'Tin của A'));
        await settle();

        service.bindUser('uid-b');

        expect(service.inbox, isEmpty);
        expect(service.messages, isEmpty);
      });

      test('the same id can be delivered to B after A signed out', () async {
        service.bindUser('uid-a');
        await service.initialize();
        gateway.foreground
            .add(shared(fcmId: 'fcm-a', recipient: 'uid-a', title: 'Tin của A'));
        await settle();

        service.clearHistory();
        service.bindUser('uid-b');
        gateway.foreground
            .add(shared(fcmId: 'fcm-b', recipient: 'uid-b', title: 'Tin của B'));
        await settle();

        expectAgree(service, 'uid-b', 'Tin của B');
      });
    });
  });
}
