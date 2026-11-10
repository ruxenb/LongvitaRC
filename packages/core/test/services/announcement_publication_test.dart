import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_core/longvita_core.dart';

AnnouncementPublication publication({
  String role = 'staff',
  String title = 'Tin mới',
}) => AnnouncementPublication(
  uid: 'test-user',
  announcement: AnnouncementModel(
    id: 'AbCdEf0123456789abcd',
    title: title,
    content: 'Nội dung tiếng Việt đầy đủ dấu.',
    authorRole: role,
    createdAt: DateTime.utc(2026, 11, 10, 12),
  ),
);

void main() {
  test('required and maximum lengths include Vietnamese Unicode', () {
    expect(AnnouncementPublication.titleError(' \n '), isNotNull);
    expect(AnnouncementPublication.contentError(''), isNotNull);
    expect(AnnouncementPublication.titleError('ố' * 120), isNull);
    expect(AnnouncementPublication.titleError('ố' * 121), isNotNull);
    expect(AnnouncementPublication.contentError('đ' * 2000), isNull);
    expect(AnnouncementPublication.contentError('đ' * 2001), isNotNull);
  });

  test(
    'payload is exactly the existing four fields and round-trips to Mobile',
    () {
      final item = publication();
      item.validate();
      final payload = item.announcement.toMap();
      expect(payload.keys.toSet(), {
        'title',
        'content',
        'authorRole',
        'createdAt',
      });
      expect(payload['createdAt'], '2026-11-10T12:00:00.000Z');
      final mobile = AnnouncementModel.fromMap(payload, item.announcement.id);
      expect(mobile.title, item.announcement.title);
      expect(mobile.content, item.announcement.content);
      expect(mobile.authorRole, 'staff');
      expect(mobile.createdAt, item.announcement.createdAt);
    },
  );

  test('rejects an unprivileged role and untrimmed fields', () {
    expect(
      () => publication(role: 'user').validate(),
      throwsA(isA<DataFailure>()),
    );
    expect(
      () => publication(title: ' Tin ').validate(),
      throwsA(isA<DataFailure>()),
    );
    publication(role: 'admin').validate();
  });

  test(
    'retry equality requires every field and rejects changes or extra fields',
    () {
      final item = publication();
      expect(item.matches(item.announcement.toMap()), isTrue);
      expect(
        item.matches({...item.announcement.toMap(), 'title': 'Changed'}),
        isFalse,
      );
      expect(
        item.matches({...item.announcement.toMap(), 'uid': 'private'}),
        isFalse,
      );
      expect(item.matches({'title': item.announcement.title}), isFalse);
    },
  );
}
