import 'package:longvita_core/models/announcement_model.dart';
import 'package:longvita_core/services/data_failure.dart';

/// One immutable publish intent, reused verbatim when its result is uncertain.
class AnnouncementPublication {
  final String uid;
  final AnnouncementModel announcement;

  const AnnouncementPublication({
    required this.uid,
    required this.announcement,
  });

  static String? titleError(String value) => _textError(value, 'tiêu đề', 120);
  static String? contentError(String value) =>
      _textError(value, 'nội dung', 2000);

  static String? _textError(String value, String label, int maximum) {
    if (value.trim().isEmpty) return 'Vui lòng nhập $label.';
    if (value.trim().runes.length > maximum) {
      return '${label == 'tiêu đề' ? 'Tiêu đề' : 'Nội dung'} tối đa $maximum ký tự.';
    }
    return null;
  }

  void validate() {
    final item = announcement;
    if (uid.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9]{20}$').hasMatch(item.id) ||
        !const ['staff', 'admin'].contains(item.authorRole) ||
        titleError(item.title) != null ||
        contentError(item.content) != null ||
        item.title != item.title.trim() ||
        item.content != item.content.trim() ||
        !item.createdAt.isUtc) {
      throw const DataFailure(
        DataFailureKind.invalid,
        'Thông báo chưa hợp lệ. Hãy kiểm tra lại nội dung và tài khoản.',
      );
    }
  }

  /// Retry must never replace an existing document with different content.
  bool matches(Map<String, dynamic> stored) {
    final payload = announcement.toMap();
    return stored.length == payload.length &&
        payload.entries.every((entry) => stored[entry.key] == entry.value);
  }
}

abstract class IAnnouncementPublisher {
  /// Allocates a Firestore auto-ID locally; it does not create a document.
  String createId();

  Future<void> publish(
    AnnouncementPublication publication, {
    required bool Function() sessionIsActive,
  });
}
