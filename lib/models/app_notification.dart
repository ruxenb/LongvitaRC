/// In-app form of a push message. See the payload proposal in
/// docs/tasks/charlie-progress.md (FCM contracts pending team approval).
///
/// A push never carries a route: it names a target type and id, and the
/// router decides where that leads. Target types are a proposal until the
/// route contract is agreed with the router owner.
library;

const int notificationSchemaVersion = 1;
const Set<String> notificationTargetTypes = {'meal_plan', 'announcement'};

enum NotificationTargetIssue { none, unsupportedVersion, unknownType, missingId }

class NotificationTarget {
  final String type;
  final String id;

  const NotificationTarget(this.type, this.id);

  @override
  bool operator ==(Object other) =>
      other is NotificationTarget && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

class AppNotification {
  final String messageId;
  final String? title;
  final String? body;
  final NotificationTarget? target;

  /// Why a message that asked for a target has none. It stays in the inbox.
  final NotificationTargetIssue targetIssue;

  /// When set, only this user may see the message.
  final String? recipientUid;

  /// The message this was parsed from. It travels with the entry, so what is
  /// accepted, held, deduplicated or dropped is the same for both forms.
  final Object? source;

  const AppNotification({
    required this.messageId,
    this.title,
    this.body,
    this.target,
    this.targetIssue = NotificationTargetIssue.none,
    this.recipientUid,
    this.source,
  });

  /// Returns null when no message id exists, since it could not be deduplicated.
  static AppNotification? parse({
    required Map<String, dynamic> data,
    String? fcmMessageId,
    String? title,
    String? body,
    Object? source,
  }) {
    final messageId = _text(data['message_id']) ?? _text(fcmMessageId);
    if (messageId == null) return null;

    final (target, issue) = _parseTarget(data);
    return AppNotification(
      messageId: messageId,
      title: title,
      body: body,
      target: target,
      targetIssue: issue,
      recipientUid: _text(data['recipient_uid']),
      source: source,
    );
  }

  /// The form kept on the device. [source] stays out: it only lives in memory.
  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'title': title,
        'body': body,
        'target_type': target?.type,
        'target_id': target?.id,
        'target_issue': targetIssue.name,
        'recipient_uid': recipientUid,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final type = json['target_type'] as String?;
    final id = json['target_id'] as String?;
    return AppNotification(
      messageId: json['message_id'] as String,
      title: json['title'] as String?,
      body: json['body'] as String?,
      target: type != null && id != null ? NotificationTarget(type, id) : null,
      targetIssue: NotificationTargetIssue.values.firstWhere(
        (issue) => issue.name == json['target_issue'],
        orElse: () => NotificationTargetIssue.none,
      ),
      recipientUid: json['recipient_uid'] as String?,
    );
  }

  static (NotificationTarget?, NotificationTargetIssue) _parseTarget(
      Map<String, dynamic> data) {
    final type = _text(data['target_type']);
    if (type == null) return (null, NotificationTargetIssue.none);

    if (_text(data['schema_version']) != '$notificationSchemaVersion') {
      return (null, NotificationTargetIssue.unsupportedVersion);
    }
    if (!notificationTargetTypes.contains(type)) {
      return (null, NotificationTargetIssue.unknownType);
    }
    final id = _text(data['target_id']);
    if (id == null) return (null, NotificationTargetIssue.missingId);
    return (NotificationTarget(type, id), NotificationTargetIssue.none);
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
