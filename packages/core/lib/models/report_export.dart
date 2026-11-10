import 'package:longvita_core/models/report_metadata.dart';

/// One immutable local PDF. Retry sends its original metadata and bytes.
class ReportExport {
  final String exportId;
  final String? planId;
  final String filePath;
  final String createdAt;
  final int sizeBytes;

  const ReportExport({
    required this.exportId,
    required this.planId,
    required this.filePath,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get fileName => '$exportId.pdf';

  /// Legacy files stay on disk under their original name, but never expose
  /// that name (which may contain a UID) to another application.
  String get externalFileName =>
      ReportMetadata.exportIdPattern.hasMatch(exportId)
      ? fileName
      : 'Longvita-report.pdf';

  ReportMetadata get metadata => ReportMetadata(
    exportId: exportId,
    planId: planId,
    createdAt: createdAt,
    sizeBytes: sizeBytes,
  );
}
