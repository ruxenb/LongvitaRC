import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:longvita_core/models/app_notification.dart';
import 'package:longvita/firebase/notification_history_store.dart';
import 'package:longvita/firebase/notification_inbox.dart';

enum NotificationPermission { unknown, granted, denied, failed }

/// Runs in its own isolate when a message arrives in background or terminated
/// state, so it can never navigate, and it does not know who is signed in. A
/// message naming a recipient waits on the device until that user's inbox
/// takes it; one with no valid recipient is not kept. A tap reaches the app
/// through onMessageOpenedApp or getInitialMessage.
///
/// Android may already show the system notification of a notification
/// message before this runs, so senders use a generic title and body.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) debugPrint('FCM background: ${message.messageId}');
  final notification = _parseMessage(message);
  if (notification != null && notification.recipientUid != null) {
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

  /// Identifies the inbox session. It changes when a user is bound over
  /// another or nobody, and on sign-out, so work that awaited across a change
  /// (even the same user signing out and back in) can tell and stop.
  int _generation = 0;

  /// The session whose saved history has been read into the inbox. Until
  /// then nothing is saved, so a save cannot replace history not yet read,
  /// and nothing leaves the device queue. A failed read is tried again when a
  /// message arrives or the queue is drained.
  int? _loadedGeneration;

  bool get _historyLoaded => _loadedGeneration == _generation;

  /// Reads and saves of one user's history file run one after another, in the
  /// order requested: a read waits for every save requested before it, so a
  /// new session of the same user reads what an earlier session saved. Other
  /// users' files are not held up. Each completes with whether it succeeded.
  final Map<String, Future<bool>> _historyTasks = {};
  final Set<Future<void>> _pendingWrites = {};
  NotificationPermission _permission = NotificationPermission.unknown;
  AppNotification? _arrival;

  /// Called when [inbox] gains an entry or [permission] is resolved.
  void Function()? onChanged;

  NotificationService({FcmGateway? gateway, NotificationHistoryStore? history})
    : _gateway = gateway ?? FirebaseFcmGateway(),
      _history = history ?? NotificationHistoryStore();

  NotificationPermission get permission => _permission;

  List<AppNotification> get inbox => _inbox.items;

  List<RemoteMessage> get messages => _inbox.items
      .map((item) => item.source)
      .whereType<RemoteMessage>()
      .toList();

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
      _gateway.onMessageOpenedApp.listen(
        (message) => _receive(message, tapped: true),
      );

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
  ///
  /// Binding the user already bound continues their session.
  Future<void> bindUser(String uid) async {
    if (_inbox.boundUid != uid) _generation++;
    final generation = _generation;
    _inbox.bind(uid);
    await _loadHistory(uid, generation);
    if (generation != _generation) return;
    onChanged?.call();
    await drainPending();
  }

  /// Moves this user's messages received in the background into the inbox.
  /// Call when the app returns to the foreground, since a running app is not
  /// bound again. A message leaves the device queue only after the history
  /// holding it was saved; otherwise it waits for the next drain.
  Future<void> drainPending() async {
    final uid = _inbox.boundUid;
    if (uid == null) return;
    final generation = _generation;
    if (!_historyLoaded) await _loadHistory(uid, generation);
    try {
      final pending = await _history.claimPending(uid);
      if (generation != _generation || pending.isEmpty) return;
      var added = false;
      // Oldest first, because each new entry goes to the top of the inbox.
      for (final entry in pending) {
        added = _inbox.receive(entry.notification) || added;
      }
      if (added) onChanged?.call();
      // Without the saved history read, a save could replace it: the
      // messages stay queued and are shown from memory meanwhile.
      if (!_historyLoaded) return;
      final saved = await _save(uid);
      if (!saved || generation != _generation) return;
      await _history.ackPending(pending);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM pending unavailable: $e');
    }
  }

  /// Empties the in-app inbox on sign-out. The saved history stays for the same
  /// user, and a next user only ever loads their own.
  void clearHistory() {
    _generation++;
    _inbox.clear();
    _arrival = null;
  }

  /// Completes when every read and save requested so far has finished.
  @visibleForTesting
  Future<void> get savesDone async {
    while (true) {
      final tasks = List.of(_historyTasks.values);
      final writes = List.of(_pendingWrites);
      await Future.wait(writes);
      await Future.wait(tasks);
      if (_pendingWrites.isEmpty &&
          _historyTasks.values.every(tasks.contains)) {
        return;
      }
    }
  }

  /// The target of a tapped message, once. The router owner decides when to
  /// call this and where each target type leads.
  NotificationTarget? takePendingTarget() => _inbox.takePendingTarget();

  /// True once after a message was tapped. Under the temporary contract every
  /// tap opens the notification center, whatever its target.
  bool takeOpenRequest() => _inbox.takeOpenRequest();

  /// The latest message that reached the inbox while the app was open, once.
  /// Android shows no system notification then, so the app must show it.
  AppNotification? takeArrival() {
    final arrival = _arrival;
    _arrival = null;
    return arrival;
  }

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
    final added = _inbox.receive(notification, tapped: tapped);
    final uid = _inbox.boundUid;
    if (added && uid != null) {
      if (_historyLoaded) {
        unawaited(_save(uid));
      } else {
        // Keep a durable copy without replacing history we could not read.
        // It survives sign-out and is acknowledged only after a later save.
        final generation = _generation;
        late final Future<void> write;
        write = _stageUnread(notification, generation).whenComplete(() {
          _pendingWrites.remove(write);
        });
        _pendingWrites.add(write);
      }
    }
    if (added && !tapped) _arrival = notification;
    // A tap on a message already in the inbox adds nothing but must still
    // open. A message for someone else or nobody changes nothing.
    final forThisUser = uid != null && notification.isFor(uid);
    if (added || (tapped && forThisUser)) onChanged?.call();
  }

  Future<void> _stageUnread(AppNotification item, int generation) async {
    try {
      await _history.addPending(item);
      if (generation == _generation) await drainPending();
    } catch (e) {
      // Preserve the unread history even if the device cannot stage a copy.
      if (kDebugMode) debugPrint('FCM staging unavailable: $e');
    }
  }

  /// Runs [task] on [uid]'s history after the tasks already requested for it.
  Future<bool> _historyTask(String uid, Future<bool> Function() task) {
    final previous = _historyTasks[uid] ?? Future.value(true);
    final next = previous.then((_) async {
      try {
        return await task();
      } catch (e) {
        if (kDebugMode) debugPrint('FCM history task failed: $e');
        return false;
      }
    });
    _historyTasks[uid] = next;
    return next;
  }

  /// Reads [uid]'s saved history into the inbox of session [generation],
  /// after that user's earlier saves. A read that fails leaves the session
  /// unloaded, so nothing replaces the file until a later read succeeds.
  /// Messages already in the inbox are saved together with what was read.
  Future<bool> _loadHistory(String uid, int generation) =>
      _historyTask(uid, () async {
        if (generation != _generation || _loadedGeneration == generation) {
          return false;
        }
        final List<AppNotification> saved;
        try {
          saved = await _history.load(uid);
        } catch (e) {
          // The inbox keeps working in memory meanwhile.
          if (kDebugMode) debugPrint('FCM history unavailable: $e');
          return false;
        }
        if (generation != _generation) return false;
        final before = _inbox.items.length;
        _inbox.restore(saved);
        _loadedGeneration = generation;
        if (before > 0) await _history.save(uid, _inbox.items);
        return true;
      });

  /// Saves the inbox as it is now, after the reads and saves already
  /// requested for [uid]. Call only once the history of this session is read:
  /// the inbox then holds it, so the save replaces nothing unread.
  Future<bool> _save(String uid) {
    final items = _inbox.items;
    return _historyTask(uid, () async {
      await _history.save(uid, items);
      return true;
    });
  }
}
