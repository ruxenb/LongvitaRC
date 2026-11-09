import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/report_metadata.dart';
import 'package:longvita/services/data_failure.dart';
import 'package:longvita/services/firestore_report_metadata_repository.dart';

const exportId = 'pdf_20261109T040000Z_0123456789abcdef';

ReportMetadata metadata({String? planId = 'saved-plan'}) => ReportMetadata(
  exportId: exportId,
  planId: planId,
  createdAt: '2026-11-09T04:00:00.000Z',
  sizeBytes: 20000,
);

void main() {
  group('ReportMetadata', () {
    test('roundtrips exactly the six public fields, including null plan', () {
      for (final planId in ['saved-plan', null]) {
        final value = metadata(planId: planId);
        final data = value.toMap();
        expect(data.keys, unorderedEquals(ReportMetadata.fields));
        expect(data['planId'], planId);
        expect(data['fileName'], '$exportId.pdf');
        expect(ReportMetadata.fromMap(data, exportId), value);
        expect(ReportMetadata.fromMap(data, exportId).hashCode, value.hashCode);
        data['filePath'] = '/private/device/path';
        expect(value.toMap().containsKey('filePath'), isFalse);
      }
    });

    test('new exports in the same clock tick have distinct non-PII names', () {
      final random = Random(73);
      final instant = DateTime.utc(2026, 11, 9, 4);
      final exports = List.generate(
        100,
        (_) => ReportMetadata.forNewExport(
          createdAt: instant,
          planId: 'private-user_saved-plan',
          sizeBytes: 100,
          random: random,
        ),
      );
      expect(exports.map((e) => e.exportId).toSet(), hasLength(100));
      for (final value in exports) {
        expect(ReportMetadata.exportIdPattern.hasMatch(value.exportId), isTrue);
        expect(value.fileName, isNot(contains('private-user')));
        expect(value.createdAt, '2026-11-09T04:00:00.000Z');
      }
    });

    test('normalizes creation time to UTC once', () {
      final time = DateTime.parse('2026-11-09T11:00:00+07:00');
      final value = ReportMetadata.forNewExport(
        createdAt: time,
        planId: null,
        sizeBytes: 1,
        random: Random(1),
      );
      expect(value.createdAt, '2026-11-09T04:00:00.000Z');
      expect(value.exportId, startsWith('pdf_20261109T040000Z_'));
    });

    test('rejects malformed or private fields on deserialization', () {
      final original = metadata().toMap();
      final invalid = <Map<String, Object?>>[
        {...original}..remove('planId'),
        {...original, 'uid': 'someone'},
        {...original, 'filePath': '/device/file'},
        {...original, 'downloadUrl': 'https://example.test/private'},
        {...original, 'fileName': 'wrong.pdf'},
        {...original, 'sizeBytes': 1.0},
        {...original, 'sizeBytes': 0},
        {...original, 'sizeBytes': ReportMetadata.maxSizeBytes + 1},
        {...original, 'schemaVersion': 1.0},
        {...original, 'schemaVersion': 2},
        {...original, 'createdAt': '2026-11-09T04:00:00+00:00'},
        {...original, 'planId': ''},
        {...original, 'planId': '../other'},
        {...original, 'planId': '.'},
        {...original, 'planId': '..'},
      ];
      for (var i = 0; i < invalid.length; i++) {
        expect(
          () => ReportMetadata.fromMap(invalid[i], exportId),
          throwsFormatException,
          reason: 'invalid case $i',
        );
      }
      expect(
        () => ReportMetadata.fromMap(original, 'different-document'),
        throwsFormatException,
      );
    });

    test('validates Firestore path IDs by UTF-8 bytes', () {
      expect(ReportMetadata.isValidDocumentId('a' * 1500), isTrue);
      expect(ReportMetadata.isValidDocumentId('a' * 1501), isFalse);
      expect(ReportMetadata.isValidDocumentId('ệ' * 501), isFalse);
      expect(ReportMetadata.isValidDocumentId('parent/child'), isFalse);
    });

    test('accepts the size boundaries and rejects UID-shaped export names', () {
      for (final size in [1, ReportMetadata.maxSizeBytes]) {
        expect(
          ReportMetadata(
            exportId: exportId,
            planId: null,
            createdAt: '2026-11-09T04:00:00Z',
            sizeBytes: size,
          ).sizeBytes,
          size,
        );
      }
      expect(
        () => ReportMetadata(
          exportId: 'private-user_12345',
          planId: null,
          createdAt: '2026-11-09T04:00:00Z',
          sizeBytes: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('FirestoreReportMetadataRepository', () {
    test(
      'writes one full owner-scoped document with no extra fields',
      () async {
        var writes = 0;
        final value = metadata();
        final repository = FirestoreReportMetadataRepository.withWriter((
          path,
          data,
        ) async {
          writes++;
          expect(path, 'users/owner/report_exports/$exportId');
          expect(data, value.toMap());
        });
        await repository.save('owner', value);
        expect(writes, 1);
      },
    );

    test('keeps the original write pending until its completion', () async {
      final gate = Completer<void>();
      final started = Completer<void>();
      var writes = 0;
      var completed = false;
      final repository = FirestoreReportMetadataRepository.withWriter((_, _) {
        writes++;
        started.complete();
        return gate.future;
      });
      final result = repository.save('owner', metadata());
      final observed = result.then((_) => completed = true);
      await started.future;
      await Future<void>.value();
      expect(completed, isFalse);
      expect(writes, 1);
      gate.complete();
      await observed;
      expect(completed, isTrue);
      expect(writes, 1);
    });

    test(
      'retries the same immutable payload without changing identity',
      () async {
        final calls = <(String, Map<String, Object?>)>[];
        final repository = FirestoreReportMetadataRepository.withWriter((
          path,
          data,
        ) async {
          calls.add((path, Map.of(data)));
          if (calls.length == 1) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            );
          }
        });
        final value = metadata();
        await expectLater(
          repository.save('owner', value),
          throwsA(
            isA<DataFailure>().having(
              (e) => e.kind,
              'kind',
              DataFailureKind.permission,
            ),
          ),
        );
        await repository.save('owner', value);
        expect(calls, hasLength(2));
        expect(calls[0].$1, calls[1].$1);
        expect(calls[0].$2, calls[1].$2);
      },
    );

    test('invalid owner IDs never reach the SDK', () async {
      var writes = 0;
      final repository = FirestoreReportMetadataRepository.withWriter(
        (_, _) async => writes++,
      );
      for (final uid in ['', '.', '..', 'owner/other', 'ệ' * 501]) {
        await expectLater(
          repository.save(uid, metadata()),
          throwsA(isA<DataFailure>()),
        );
      }
      expect(writes, 0);
    });

    test(
      'preserves classified SDK failures, including late rejections',
      () async {
        final gate = Completer<void>();
        final repository = FirestoreReportMetadataRepository.withWriter(
          (_, _) => gate.future,
        );
        final expected = expectLater(
          repository.save('owner', metadata()),
          throwsA(
            isA<DataFailure>().having(
              (e) => e.kind,
              'kind',
              DataFailureKind.offline,
            ),
          ),
        );
        gate.completeError(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );
        await expected;
      },
    );
  });
}
