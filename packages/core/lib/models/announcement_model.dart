class AnnouncementModel {
  static const supportedTargetRoles = {'admin', 'staff', 'user'};

  final String id;
  final String title;
  final String content;
  final String authorRole; // 'admin' | 'staff'
  final List<String> targetRoles;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.authorRole = 'staff',
    this.targetRoles = const ['admin', 'staff', 'user'],
    required this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      authorRole: map['authorRole'] as String? ?? 'staff',
      targetRoles:
          (map['targetRoles'] as List<dynamic>?)
              ?.whereType<String>()
              .where(supportedTargetRoles.contains)
              .toSet()
              .toList(growable: false) ??
          const ['admin', 'staff', 'user'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
                ? map['createdAt'] as DateTime
                : DateTime.tryParse(map['createdAt'].toString()) ??
                      DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorRole': authorRole,
      'targetRoles': targetRoles,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
