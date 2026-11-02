import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'notification_inbox.dart';

enum NotificationPermission { unknown, granted, denied, failed }

/// Runs in its own isolate when a message arrives in background or terminated
/// state, so it can never navigate. It stores nothing until the history policy
/// is agreed: the system tray shows the notification, and a tap reaches the app
/// through onMessageOpenedApp or getInitialMessage.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) debugPrint('FCM background: ${message.messageId}');
}

/// The Firebase Messaging calls [NotificationService] depends on.
abstract interface class FcmGateway {
  Future<bool> requestPermission();
  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Future<RemoteMessage?> getInitialMessage();
  void registerBackgroundHandler();
  Future<String?> getToken();
}

class FirebaseFcmGateway implements FcmGateway {
  final FirebaseMessaging _fcm;

  FirebaseFcmGateway({FirebaseMessaging? fcm})
      : _fcm = fcm ?? FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() => _fcm.getInitialMessage();

  @override
  void registerBackgroundHandler() =>
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  @override
  Future<String?> getToken() => _fcm.getToken();
}

class NotificationService {
  final FcmGateway _gateway;
  final NotificationInbox _inbox = NotificationInbox();
  bool _initialized = false;
  NotificationPermission _permission = NotificationPermission.unknown;

  NotificationService({FcmGateway? gateway})
      : _gateway = gateway ?? FirebaseFcmGateway();

  NotificationPermission get permission => _permission;

  List<AppNotification> get inbox => _inbox.items;

  List<RemoteMessage> get messages =>
      _inbox.items.map((item) => item.source).whereType<RemoteMessage>().toList();

  /// Requests permission and attaches listeners once per app process.
  ///
  /// A denied permission still attaches them: the app may be opened from an
  /// earlier notification, and denial must not read as a failure.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _permission = await _gateway.requestPermission()
          ? NotificationPermission.granted
          : NotificationPermission.denied;
      _gateway.registerBackgroundHandler();
      _gateway.onMessage.listen((message) => _receive(message));
      _gateway.onMessageOpenedApp
          .listen((message) => _receive(message, tapped: true));

      final initial = await _gateway.getInitialMessage();
      if (initial != null) _receive(initial, tapped: true);
    } catch (e) {
      _permission = NotificationPermission.failed;
      if (kDebugMode) debugPrint('FCM init failed: $e');
    }
  }

  /// Starts the inbox of the signed-in user.
  void bindUser(String uid) => _inbox.bind(uid);

  /// Drops the in-app history of the previous user on sign-out.
  void clearHistory() => _inbox.clear();

  /// The target of a tapped message, once. The router owner decides when to
  /// call this and where each target type leads.
  NotificationTarget? takePendingTarget() => _inbox.takePendingTarget();

  Future<String?> getToken() async {
    try {
      return await _gateway.getToken();
    } catch (_) {
      return null;
    }
  }

  void _receive(RemoteMessage message, {bool tapped = false}) {
    final notification = AppNotification.parse(
      data: message.data,
      fcmMessageId: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
      source: message,
    );
    if (notification == null) return;
    _inbox.receive(notification, tapped: tapped);
  }
}
