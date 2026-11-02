import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/upload_failure.dart';

class StorageService {
  /// Set with --dart-define to run against the local Storage emulator, for
  /// example 10.0.2.2 from an Android emulator. Empty in every other build.
  static const _emulatorHost = String.fromEnvironment('STORAGE_EMULATOR_HOST');
  static const _emulatorPort = 9199;

  final FirebaseStorage _storage;
  UploadTask? _activeUpload;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance {
    // The default of ten minutes leaves an offline upload looking stuck.
    _storage.setMaxUploadRetryTime(const Duration(seconds: 60));
    if (_emulatorHost.isNotEmpty) {
      unawaited(_storage.useStorageEmulator(_emulatorHost, _emulatorPort));
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
    try {
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
        'project-not-found' =>
          UploadFailureKind.notConfigured,
        _ => UploadFailureKind.unknown,
      };
}
