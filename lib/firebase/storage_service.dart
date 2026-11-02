import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String?> uploadReportPdf({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    StreamSubscription<TaskSnapshot>? progress;
    try {
      final ref = _storage.ref().child('reports/$uid/$fileName');
      final metadata = SettableMetadata(contentType: 'application/pdf');
      final uploadTask = ref.putData(bytes, metadata);

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
    } catch (_) {
      return null;
    } finally {
      await progress?.cancel();
    }
  }
}
