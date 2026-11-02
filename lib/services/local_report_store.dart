import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Keeps exported PDFs on the device under `reports/{uid}/{exportId}.pdf`, so
/// a file survives a failed upload and a retry can reuse the same export id.
class LocalReportStore {
  final Future<Directory> Function() _baseDirectory;

  LocalReportStore({Future<Directory> Function()? baseDirectory})
      : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  /// Writes through a temporary file: an interrupted write never leaves a
  /// partial PDF under the final name. Saving the same id replaces the file.
  Future<File> save({
    required String uid,
    required String exportId,
    required Uint8List bytes,
  }) async {
    final file = await _fileFor(uid, exportId);
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    return temp.rename(file.path);
  }

  /// Returns the saved file, or null when it does not exist.
  Future<File?> find({required String uid, required String exportId}) async {
    final file = await _fileFor(uid, exportId);
    return await file.exists() ? file : null;
  }

  /// Returns the saved bytes, or null when the file does not exist.
  Future<Uint8List?> read({required String uid, required String exportId}) async {
    final file = await find(uid: uid, exportId: exportId);
    return file?.readAsBytes();
  }

  Future<File> _fileFor(String uid, String exportId) async {
    _checkSegment(uid);
    _checkSegment(exportId);
    final base = await _baseDirectory();
    return File('${base.path}/reports/$uid/$exportId.pdf');
  }

  /// Ids become path segments, so they must not be able to leave the folder.
  static void _checkSegment(String value) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      throw ArgumentError.value(value, 'id', 'not a safe file name');
    }
  }
}
