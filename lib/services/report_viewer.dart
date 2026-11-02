import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Opens a PDF with the platform's viewer or share sheet. Returns false when
/// it could not be shown; the user closing the dialog is not a failure.
abstract interface class IReportViewer {
  Future<bool> preview(Uint8List bytes, String fileName);
  Future<bool> share(Uint8List bytes, String fileName);
}

class PrintingReportViewer implements IReportViewer {
  @override
  Future<bool> preview(Uint8List bytes, String fileName) async {
    // layoutPdf answers false when the dialog is cancelled, and throws on a
    // real failure, so its result says nothing about whether the PDF opened.
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: fileName,
    );
    return true;
  }

  @override
  Future<bool> share(Uint8List bytes, String fileName) =>
      Printing.sharePdf(bytes: bytes, filename: fileName);
}
