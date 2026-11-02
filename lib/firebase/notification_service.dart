import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'notification_history_store.dart';
import 'notification_inbox.dart';

enum NotificationPermission { unknown, granted, denied, failed }

/// Runs in its own isolate when a message arrives in background or terminated
/// state, so it can never navigate, and it does not know who is signed in. The
/// message waits on the device until the app adds it to that user's inbox. A
/// tap reaches the app through onMessageOpenedApp or getInitialMessage.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) debugPrint('FCM background: ${message.messageId}');
  final notification = _parseMessage(message);
  if (notification != null) {
    await NotificationHistoryStore().addPending(notification);
  }
}

AppNotification? _parseMessage(RemoteMessage message) => AppNotification.parse(
      data: message.data,
      fcmMessageId: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
      source: message,
    );

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
  final NotificationHistoryStore _history;
  final NotificationInbox _inbox = NotificationInbox();
  bool _initialized = false;

  /// Saves run one after another, so an older inbox never overwrites a newer.
  Future<void> _lastSave = Future.value();
  NotificationPermission _permission = NotificationPermission.unknown;

  /// Called when [inbox] gains an entry or [permission] is resolved.
  void Function()? onChanged;

  NotificationService({FcmGateway? gateway, NotificationHistoryStore? history})
      : _gateway = gateway ?? FirebaseFcmGateway(),
        _history = history ?? NotificationHistoryStore();

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
      // Debug builds only: the Console needs this to send a test message.
      if (kDebugMode) debugPrint('FCM token: ${await getToken()}');
    } catch (e) {
      _permission = NotificationPermission.failed;
      if (kDebugMode) debugPrint('FCM init failed: $e');
    }
    onChanged?.call();
  }

  /// Starts the inbox of the signed-in user and brings back their history.
  /// The inbox still works in memory when the device files cannot be used.
  Future<void> bindUser(String uid) async {
    _inbox.bind(uid);
    try {
      final saved = await _history.load(uid);
      if (_inbox.boundUid != uid) return;
      _inbox.restore(saved);
      await drainPending();
    } catch (e) {
      if (kDebugMode) debugPrint('FCM history unavailable: $e');
    }
    onChanged?.call();
  }

  /// Moves messages received in the background into the inbox. Call when the
  /// app returns to the foreground, since a running app is not bound again.
  Future<void> drainPending() async {
    final uid = _inbox.boundUid;
    if (uid == null) return;
    try {
      final pending = await _history.takePending();
      if (_inbox.boundUid != uid) return;
      var added = false;
      // Oldest first, because each new entry goes to the top of the inbox.
      for (final item in pending.reversed) {
        added = _inbox.receive(item) || added;
      }
      if (added) onChanged?.call();
      await _save(uid);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM pending unavailable: $e');
    }
  }

  /// Empties the in-app inbox on sign-out. The saved history stays for the same
  /// user, and a next user only ever loads their own.
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
    final notification = _parseMessage(message);
    if (notification == null) return;
    if (_inbox.receive(notification, tapped: tapped)) {
      onChanged?.call();
      final uid = _inbox.boundUid;
      if (uid != null) unawaited(_save(uid));
    }
  }

  Future<void> _save(String uid) {
    final items = _inbox.items;
    return _lastSave = _lastSave.then((_) => _history.save(uid, items)).catchError(
      (Object e) {
        if (kDebugMode) debugPrint('FCM history not saved: $e');
      },
    );
  }
}
