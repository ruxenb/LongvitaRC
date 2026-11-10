import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:longvita_core/models/upload_failure.dart';
import 'package:longvita/config/pdf_export_mode.dart';

class StorageService {
  final FirebaseStorage _storage;
  late final Future<UploadFailure?> _ready;
  UploadTask? _activeUpload;
  int _generation = 0;

  /// This adapter is exclusively for the local technology demonstration.
  /// Final builds do not construct it; no path falls back to production.
  factory StorageService({
    FirebaseStorage? storage,
    String emulatorHost = storageEmulatorHost,
  }) {
    if (!isLocalStorageHost(emulatorHost)) {
      throw ArgumentError.value(
        emulatorHost,
        'emulatorHost',
        'local host required',
      );
    }
    return StorageService._(storage ?? FirebaseStorage.instance, emulatorHost);
  }

  StorageService._(this._storage, String host) {
    _ready = _configure(host);
  }

  Future<UploadFailure?> _configure(String host) async {
    try {
      _storage.setMaxUploadRetryTime(const Duration(seconds: 60));
      await _storage.useStorageEmulator(host, 9199);
      return null;
    } catch (error) {
      // Handle immediately, even if no upload is ever requested.
      return UploadFailure(UploadFailureKind.notConfigured, cause: error);
    }
  }

  /// Returns the download URL. Throws [UploadFailure] when the file does not
  /// reach Storage, including after [cancelActiveUpload].
  Future<String> uploadReportPdf({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    StreamSubscription<TaskSnapshot>? progress;
    UploadTask? uploadTask;
    final generation = _generation;
    try {
      final setupFailure = await _ready;
      if (setupFailure != null) throw setupFailure;
      if (generation != _generation) {
        throw const UploadFailure(UploadFailureKind.cancelled);
      }
      final ref = _storage.ref().child('reports/$uid/$fileName');
      final metadata = SettableMetadata(contentType: 'application/pdf');
      uploadTask = _activeUpload = ref.putData(bytes, metadata);

      progress = uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0 && onProgress != null) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        },
        // The stream repeats the failure that awaiting the task reports below.
        // Without this handler it surfaces as an unhandled exception.
        onError: (Object _) {},
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on UploadFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw UploadFailure(_kindOf(e.code), code: e.code, cause: e);
    } catch (e) {
      throw UploadFailure(UploadFailureKind.unknown, cause: e);
    } finally {
      if (identical(_activeUpload, uploadTask)) _activeUpload = null;
      await progress?.cancel();
    }
  }

  /// Stops the running upload, if any. Its call to [uploadReportPdf] then fails
  /// with [UploadFailureKind.cancelled].
  Future<void> cancelActiveUpload() async {
    _generation++;
    try {
      await _activeUpload?.cancel();
    } catch (_) {
      // Already finished: its own outcome has been or will be reported.
    }
  }

  /// A project with no Storage bucket reports object-not-found on upload.
  static UploadFailureKind _kindOf(String code) => switch (code) {
    'canceled' => UploadFailureKind.cancelled,
    'unauthorized' || 'unauthenticated' => UploadFailureKind.denied,
    'retry-limit-exceeded' => UploadFailureKind.network,
    'quota-exceeded' => UploadFailureKind.quota,
    'object-not-found' ||
    'bucket-not-found' ||
    'project-not-found' => UploadFailureKind.notConfigured,
    _ => UploadFailureKind.unknown,
  };
}
