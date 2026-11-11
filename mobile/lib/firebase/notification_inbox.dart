import 'package:longvita_core/models/app_notification.dart';

/// Per-user inbox rules, free of Firebase so they can be unit tested.
/// Contract FCM v1:
///
/// - A message is accepted only for the user its `recipient_uid` names
///   exactly. With no valid recipient it is never accepted, held, routed or
///   announced, and it is not given to whoever signs in next.
/// - One message reaching several callbacks gives one entry and one open.
/// - The first accepted message wins: a later one with the same id changes
///   neither the entry nor what a tap does. A rejected message changes nothing.
/// - A message with a recipient that arrives with nobody signed in waits for
///   that user's sign-in in this process, and is dropped on sign-out.
/// - Restored history is checked again: only entries for the bound user count.
///
/// This class holds the inbox in memory; `NotificationService` saves and
/// restores it per user.
class NotificationInbox {
  /// Messages held for a sign-in, at most this many, newest kept.
  static const maxHeld = 50;

  String? _uid;
  final List<AppNotification> _items = [];
  final List<_Held> _held = [];
  final Map<String, AppNotification> _accepted = {};
  final Set<String> _routed = {};
  NotificationTarget? _pendingTarget;
  bool _openRequested = false;

  List<AppNotification> get items => List.unmodifiable(_items);

  String? get boundUid => _uid;

  /// Starts [uid]'s session and delivers what arrived for them before
  /// sign-in. What was held for anyone else is dropped.
  void bind(String uid) {
    if (_uid != uid) _resetSession();
    _uid = uid;
    final held = List.of(_held);
    _held.clear();
    for (final item in held) {
      receive(item.notification, tapped: item.tapped);
    }
  }

  /// Adds saved history of the bound user behind what is already in the inbox.
  /// Entries for another or no recipient are skipped, whatever file they came
  /// from. Later messages with the same id count as duplicates.
  void restore(List<AppNotification> saved) {
    final uid = _uid;
    if (uid == null) return;
    for (final item in saved) {
      if (!item.isFor(uid)) continue;
      if (_accepted.containsKey(item.messageId)) continue;
      _accepted[item.messageId] = item;
      _items.add(item);
    }
  }

  /// Ends the session: nothing of this user stays for the next one.
  void clear() {
    _uid = null;
    _held.clear();
    _resetSession();
  }

  /// Returns true when the message was added to the inbox as a new entry.
  bool receive(AppNotification notification, {bool tapped = false}) {
    final recipient = notification.recipientUid;
    final isAnnouncement = notification.target?.type == 'announcement';
    if (recipient == null && !isAnnouncement) return false;

    final uid = _uid;
    if (uid == null) {
      _held.add(_Held(notification, tapped));
      if (_held.length > maxHeld) _held.removeAt(0);
      return false;
    }
    if (recipient != null && recipient != 'all' && recipient != uid && !isAnnouncement) {
      return false;
    }

    final accepted = _accepted[notification.messageId];
    if (accepted == null) {
      _accepted[notification.messageId] = notification;
      _items.insert(0, notification);
    }

    final target = (accepted ?? notification).target;
    if (tapped && _routed.add(notification.messageId)) {
      _openRequested = true;
      if (target != null) _pendingTarget = target;
    }
    return accepted == null;
  }

  /// Hands the tapped target to whoever routes it, once. Metadata only in v1:
  /// every accepted tap opens the notification center.
  NotificationTarget? takePendingTarget() {
    final target = _pendingTarget;
    _pendingTarget = null;
    return target;
  }

  /// True once after a message was tapped, with or without a target.
  bool takeOpenRequest() {
    final requested = _openRequested;
    _openRequested = false;
    return requested;
  }

  void _resetSession() {
    _items.clear();
    _accepted.clear();
    _routed.clear();
    _pendingTarget = null;
    _openRequested = false;
  }
}

class _Held {
  final AppNotification notification;
  final bool tapped;

  const _Held(this.notification, this.tapped);
}
