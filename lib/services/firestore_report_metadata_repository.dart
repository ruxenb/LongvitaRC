import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/report_metadata.dart';
import 'data_failure.dart';
import 'i_report_metadata_repository.dart';

/// Writes one full document, never merged.
typedef ReportMetadataWriter = Future<void> Function(
  String path,
  Map<String, Object?> data,
);

/// Firestore implementation of [IReportMetadataRepository].
///
/// `set()` without merge: the rules allow a create, or an update only when
/// the payload is identical (idempotent retry); any other payload under the
/// same ID is a collision and is rejected. No timeout is applied here, so a
/// write queued offline stays the same pending Future until the server acks.
class FirestoreReportMetadataRepository implements IReportMetadataRepository {
  static const collection = 'report_exports';

  final ReportMetadataWriter _write;

  FirestoreReportMetadataRepository({FirebaseFirestore? firestore})
    : this.withWriter(
        _firestoreWriter(firestore ?? FirebaseFirestore.instance),
      );

  /// Lets unit tests observe the path, payload and the pending Future without
  /// a Firestore instance. The real SDK path is checked on Android (S1/S2).
  @visibleForTesting
  FirestoreReportMetadataRepository.withWriter(this._write);

  static ReportMetadataWriter _firestoreWriter(FirebaseFirestore firestore) =>
      (path, data) => firestore.doc(path).set(data);

  static String documentPath(String uid, String exportId) =>
      'users/$uid/$collection/$exportId';

  @override
  Future<void> save(String uid, ReportMetadata metadata) async {
    if (!ReportMetadata.isValidDocumentId(uid)) {
      throw const DataFailure(
        DataFailureKind.permission,
        'Bạn chưa có quyền thực hiện thao tác. Hãy đăng nhập lại.',
      );
    }
    try {
      await _write(documentPath(uid, metadata.exportId), metadata.toMap());
    } catch (error) {
      throw DataFailure.from(error);
    }
  }
}
