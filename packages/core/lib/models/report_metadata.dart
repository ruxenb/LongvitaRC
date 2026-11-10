import 'dart:convert';
import 'dart:math';

/// Metadata of one PDF export, stored at
/// `users/{uid}/report_exports/{exportId}` (docs/pdf-export-contract.md §3).
///
/// Every field is immutable. A metadata retry sends this exact object again,
/// so the server can accept it as a no-op update and reject anything else as
/// an ID collision. It never carries the UID, names, the plan title, PDF
/// bytes, local paths or URLs.
class ReportMetadata {
  static const int schemaVersion = 1;
  static const int maxSizeBytes = 10 * 1024 * 1024;

  /// Firestore document IDs are at most 1500 bytes.
  static const int maxPlanIdLength = 1500;

  static final RegExp exportIdPattern = RegExp(
    r'^pdf_[0-9]{8}T[0-9]{6}Z_[0-9a-f]{16}$',
  );
  static final RegExp createdAtPattern = RegExp(
    r'^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{1,6})?Z$',
  );

  /// The six keys of [toMap], in schema order.
  static const List<String> fields = [
    'exportId',
    'planId',
    'createdAt',
    'fileName',
    'sizeBytes',
    'schemaVersion',
  ];

  final String exportId;

  /// ID in `meal_plans`, or null when the exported plan was never saved.
  final String? planId;

  /// ISO-8601 UTC, captured once when the export starts. Client time, not a
  /// server timestamp.
  final String createdAt;
  final int sizeBytes;

  ReportMetadata({
    required this.exportId,
    required this.planId,
    required this.createdAt,
    required this.sizeBytes,
  }) {
    final problem = _validate();
    if (problem != null) throw ArgumentError(problem);
  }

  /// Metadata for a new export: a fresh ID derived from [createdAt] and 64
  /// random bits. Each user action gets a new one; retries reuse the object.
  factory ReportMetadata.forNewExport({
    required DateTime createdAt,
    required String? planId,
    required int sizeBytes,
    Random? random,
  }) {
    final utc = createdAt.toUtc();
    return ReportMetadata(
      exportId: newExportId(utc, random ?? Random.secure()),
      planId: planId,
      createdAt: utc.toIso8601String(),
      sizeBytes: sizeBytes,
    );
  }

  /// `pdf_{yyyyMMdd'T'HHmmss'Z'}_{16 hex}`. Contains neither a plan ID nor a
  /// UID, so a shared file name does not leak the account.
  static String newExportId(DateTime createdAt, Random random) {
    final t = createdAt.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${t.year.toString().padLeft(4, '0')}${two(t.month)}'
        '${two(t.day)}T${two(t.hour)}${two(t.minute)}${two(t.second)}Z';
    String hex32() =>
        random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0');
    return 'pdf_${stamp}_${hex32()}${hex32()}';
  }

  /// True when [id] can be used as one path segment: the same check the
  /// rules make on `planId` (non-empty, no '/', bounded length), plus the
  /// two names Firestore reserves.
  static bool isValidDocumentId(String id) =>
      id.isNotEmpty &&
      utf8.encode(id).length <= maxPlanIdLength &&
      !id.contains('/') &&
      id != '.' &&
      id != '..';

  String get fileName => '$exportId.pdf';

  /// Exactly the six schema fields; `planId` is written as null when unsaved.
  Map<String, Object?> toMap() => {
    'exportId': exportId,
    'planId': planId,
    'createdAt': createdAt,
    'fileName': fileName,
    'sizeBytes': sizeBytes,
    'schemaVersion': schemaVersion,
  };

  /// Reads a stored document; throws [FormatException] for any other shape.
  factory ReportMetadata.fromMap(Map<String, Object?> map, String documentId) {
    final keys = map.keys.toSet();
    if (keys.length != fields.length || !keys.containsAll(fields)) {
      throw const FormatException('report_exports: unexpected fields');
    }
    final exportId = map['exportId'];
    final planId = map['planId'];
    final createdAt = map['createdAt'];
    final sizeBytes = map['sizeBytes'];
    if (exportId is! String ||
        exportId != documentId ||
        (planId != null && planId is! String) ||
        createdAt is! String ||
        sizeBytes is! int ||
        map['schemaVersion'] != schemaVersion ||
        map['schemaVersion'] is! int ||
        map['fileName'] != '$exportId.pdf') {
      throw const FormatException('report_exports: invalid field values');
    }
    try {
      return ReportMetadata(
        exportId: exportId,
        planId: planId as String?,
        createdAt: createdAt,
        sizeBytes: sizeBytes,
      );
    } on ArgumentError catch (error) {
      throw FormatException('report_exports: ${error.message}');
    }
  }

  String? _validate() {
    if (!exportIdPattern.hasMatch(exportId)) return 'exportId format';
    if (!createdAtPattern.hasMatch(createdAt)) return 'createdAt format';
    if (sizeBytes <= 0 || sizeBytes > maxSizeBytes) return 'sizeBytes range';
    final plan = planId;
    if (plan != null && !isValidDocumentId(plan)) return 'planId segment';
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ReportMetadata &&
      other.exportId == exportId &&
      other.planId == planId &&
      other.createdAt == createdAt &&
      other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(exportId, planId, createdAt, sizeBytes);

  @override
  String toString() => 'ReportMetadata($exportId, $sizeBytes bytes)';
}
