/// In-app form of a push message. Contract FCM v1 in
/// docs/tasks/charlie-progress.md.
///
/// A push never carries a route. In v1 every accepted tap opens the
/// notification center on Profile; target type and id are kept as metadata.
///
/// A message is for one user only: [AppNotification.recipientUid] must name
/// them, or the app never shows it.
library;

const int notificationSchemaVersion = 1;

/// The form a recipient uid must have: a non-empty string of letters, digits,
/// `_` or `-` (as Firebase Auth gives for Google sign-in), compared exactly.
/// The same rule keeps a uid safe to use as a file name.
final RegExp recipientUidPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

/// The uid [value] names, or null when it is missing, not a string or not in
/// the expected form. It is not trimmed: " uid-a" is not "uid-a".
String? parseRecipientUid(Object? value) =>
    value is String && recipientUidPattern.hasMatch(value) ? value : null;

const Set<String> notificationTargetTypes = {'meal_plan', 'announcement'};

enum NotificationTargetIssue {
  none,
  unsupportedVersion,
  unknownType,
  missingId,
}

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

  /// The only user who may see the message. Null when the payload named no
  /// valid recipient: such a message is never accepted.
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
      recipientUid: parseRecipientUid(data['recipient_uid']),
      source: source,
    );
  }

  /// True when the message names exactly [uid] as its recipient.
  bool isFor(String uid) => recipientUid != null && recipientUid == uid;

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
      recipientUid: parseRecipientUid(json['recipient_uid']),
    );
  }

  /// One saved entry, or null when it is not a well-formed one, so a single
  /// bad entry does not cost the others in the same file.
  static AppNotification? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final messageId = json['message_id'];
    if (messageId is! String || messageId.trim().isEmpty) return null;
    try {
      return AppNotification.fromJson(json);
    } on TypeError {
      return null;
    }
  }

  static (NotificationTarget?, NotificationTargetIssue) _parseTarget(
    Map<String, dynamic> data,
  ) {
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
