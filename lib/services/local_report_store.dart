import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Keeps exported PDFs on the device under `reports/{uid}/{exportId}.pdf`, so
/// a file survives a failed upload and a retry can reuse the same export id.
///
/// Operations on the same uid run one after another, in call order. Sign-out
/// removes a user's files without waiting, so when the same user signs back
/// in, that removal must finish before a new PDF is written; otherwise it
/// would delete the new file too (PM-S3-5-04).
class LocalReportStore {
  final Future<Directory> Function() _baseDirectory;

  /// The last queued operation per uid. It never fails, so the next one
  /// always runs.
  final Map<String, Future<void>> _queues = {};

  LocalReportStore({Future<Directory> Function()? baseDirectory})
    : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  /// Writes through a temporary file: an interrupted write never leaves a
  /// partial PDF under the final name. Existing IDs are never overwritten.
  /// The existence check and rename share the per-UID queue with sign-out.
  Future<File> save({
    required String uid,
    required String exportId,
    required Uint8List bytes,
  }) => _queued(uid, () async {
    final file = await _fileFor(uid, exportId);
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    // Exclusive staging also prevents two store instances from racing the
    // exists/rename pair for the same ID. Check the destination AFTER taking
    // that reservation; rename removes the staging name atomically.
    await temp.create(exclusive: true);
    try {
      if (await file.exists()) {
        throw FileSystemException('PDF export ID already exists', file.path);
      }
      await temp.writeAsBytes(bytes, flush: true);
      return await temp.rename(file.path);
    } catch (_) {
      await temp.delete();
      rethrow;
    }
  });

  /// Returns the saved file, or null when it does not exist.
  Future<File?> find({required String uid, required String exportId}) =>
      _queued(uid, () => _existing(uid, exportId));

  /// Returns the saved bytes, or null when the file does not exist.
  Future<Uint8List?> read({required String uid, required String exportId}) =>
      _queued(uid, () async {
        final file = await _existing(uid, exportId);
        return file?.readAsBytes();
      });

  /// Removes one saved file, if it exists.
  Future<void> delete({required String uid, required String exportId}) =>
      _queued(uid, () async {
        final file = await _existing(uid, exportId);
        await file?.delete();
      });

  /// Removes every file of [uid] from this device. Cloud copies stay.
  Future<void> deleteAll({required String uid}) => _queued(uid, () async {
    final base = await _baseDirectory();
    final folder = Directory('${base.path}/reports/$uid');
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  /// Runs [operation] after every earlier operation on [uid] has finished.
  Future<T> _queued<T>(String uid, Future<T> Function() operation) {
    try {
      _checkSegment(uid);
    } on ArgumentError catch (e) {
      return Future.error(e);
    }
    final previous = _queues[uid] ?? Future<void>.value();
    final result = previous.then((_) => operation());
    final done = result.then<void>((_) {}, onError: (_) {});
    _queues[uid] = done;
    done.then((_) {
      if (identical(_queues[uid], done)) _queues.remove(uid);
    });
    return result;
  }

  Future<File?> _existing(String uid, String exportId) async {
    final file = await _fileFor(uid, exportId);
    return await file.exists() ? file : null;
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
