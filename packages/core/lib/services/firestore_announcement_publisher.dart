import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:longvita_core/services/data_failure.dart';
import 'package:longvita_core/services/i_announcement_publisher.dart';

/// Online, idempotent publication using the existing four-field schema.
class FirestoreAnnouncementPublisher implements IAnnouncementPublisher {
  final FirebaseFirestore _firestore;
  final String? Function() currentUid;

  FirestoreAnnouncementPublisher({
    required this.currentUid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  String createId() => _firestore.collection('announcements').doc().id;

  @override
  Future<void> publish(
    AnnouncementPublication publication, {
    required bool Function() sessionIsActive,
  }) async {
    publication.validate();
    void requireSession() {
      if (!sessionIsActive() || currentUid() != publication.uid) {
        throw const DataFailure(
          DataFailureKind.permission,
          'Phiên đăng nhập đã thay đổi. Hãy đăng nhập lại trước khi phát thông báo.',
        );
      }
    }

    try {
      requireSession();
      final item = publication.announcement;
      final profile = _firestore.collection('users').doc(publication.uid);
      final document = _firestore.collection('announcements').doc(item.id);
      await _firestore.runTransaction<void>((transaction) async {
        // The SDK can retry this callback. Never modify UI or emit analytics here.
        requireSession();
        final user = await transaction.get(profile);
        if (user.data()?['role'] != item.authorRole) {
          throw const DataFailure(
            DataFailureKind.permission,
            'Quyền tài khoản đã thay đổi. Hãy đăng nhập lại.',
          );
        }
        final existing = await transaction.get(document);
        requireSession();
        if (existing.exists) {
          if (!publication.matches(existing.data()!)) {
            throw const DataFailure(
              DataFailureKind.invalid,
              'Thông báo đã có nội dung khác. Không thể ghi đè khi thử lại.',
            );
          }
          return;
        }
        transaction.set(document, item.toMap());
      });
    } catch (error) {
      throw DataFailure.from(error);
    }
  }
}
