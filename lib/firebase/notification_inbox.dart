import '../models/app_notification.dart';

/// Per-user inbox rules, free of Firebase so they can be unit tested.
///
/// - One message reaching several callbacks gives one entry and one route.
/// - The first accepted message wins: a later one with the same id changes
///   neither the entry nor where a tap leads.
/// - A message for another recipient never enters the inbox.
/// - Messages arriving with no user signed in wait for the next sign-in, and
///   are dropped on sign-out.
///
/// This class holds the inbox in memory; `NotificationService` saves and
/// restores it per user.
class NotificationInbox {
  String? _uid;
  final List<AppNotification> _items = [];
  final List<_Held> _held = [];
  final Map<String, AppNotification> _accepted = {};
  final Set<String> _routed = {};
  NotificationTarget? _pendingTarget;

  List<AppNotification> get items => List.unmodifiable(_items);

  String? get boundUid => _uid;

  /// Starts [uid]'s session and delivers what arrived before sign-in.
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
  /// Later messages with the same id count as duplicates.
  void restore(List<AppNotification> saved) {
    for (final item in saved) {
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
    final uid = _uid;
    if (uid == null) {
      _held.add(_Held(notification, tapped));
      return false;
    }
    final recipient = notification.recipientUid;
    if (recipient != null && recipient != uid) return false;

    final accepted = _accepted[notification.messageId];
    if (accepted == null) {
      _accepted[notification.messageId] = notification;
      _items.insert(0, notification);
    }

    final target = (accepted ?? notification).target;
    if (tapped && target != null && _routed.add(notification.messageId)) {
      _pendingTarget = target;
    }
    return accepted == null;
  }

  /// Hands the tapped target to whoever routes it, once.
  NotificationTarget? takePendingTarget() {
    final target = _pendingTarget;
    _pendingTarget = null;
    return target;
  }

  void _resetSession() {
    _items.clear();
    _accepted.clear();
    _routed.clear();
    _pendingTarget = null;
  }
}

class _Held {
  final AppNotification notification;
  final bool tapped;

  const _Held(this.notification, this.tapped);
}
