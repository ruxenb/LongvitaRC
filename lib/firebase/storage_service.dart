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
    try {
      final ref = _storage.ref().child('reports/$uid/$fileName');
      final metadata = SettableMetadata(contentType: 'application/pdf');
      final uploadTask = ref.putData(bytes, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0 && onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
