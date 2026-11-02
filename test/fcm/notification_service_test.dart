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
  });
}
