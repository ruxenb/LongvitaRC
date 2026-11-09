import '../models/report_metadata.dart';

/// Stores the metadata of PDF exports. Kept apart from IDataService so the
/// existing data fakes do not change (docs/pdf-export-contract.md §10).
abstract interface class IReportMetadataRepository {
  /// Writes [metadata] to `users/{uid}/report_exports/{exportId}`.
  ///
  /// Completes when the server acknowledged the write and throws a
  /// DataFailure when it was rejected. It never times out or cancels by
  /// itself: the caller decides when to show "pending" and keeps awaiting the
  /// same Future. A retry passes the same [metadata] object again.
  Future<void> save(String uid, ReportMetadata metadata);
}
