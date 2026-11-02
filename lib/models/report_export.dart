/// A PDF saved on the device. The export id stays the same across upload
/// retries, so a retry replaces the same Storage object instead of adding one.
class ReportExport {
  final String exportId;
  final String planId;
  final String filePath;

  const ReportExport({
    required this.exportId,
    required this.planId,
    required this.filePath,
  });

  String get fileName => '$exportId.pdf';
}
