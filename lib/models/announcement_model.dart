class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String authorRole; // 'admin' | 'staff'
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.authorRole = 'staff',
    required this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      authorRole: map['authorRole'] as String? ?? 'staff',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorRole': authorRole,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
