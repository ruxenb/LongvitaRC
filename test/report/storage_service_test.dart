// A failed upload also fails the progress stream. Without an error handler that
// stream raises an unhandled exception, which fails these tests through the
// test zone. This was first seen on Android as firebase_storage/object-not-found.
import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/storage_service.dart';

class FakeSnapshot implements TaskSnapshot {
  @override
  final int bytesTransferred;
  @override
  final int totalBytes;
  final String? url;

  FakeSnapshot(this.bytesTransferred, this.totalBytes, {this.url});

  @override
  Reference get ref => FakeReference(url: url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An UploadTask is a Future of its final snapshot with a progress stream.
class FakeUploadTask implements UploadTask {
  final StreamController<TaskSnapshot> events =
      StreamController<TaskSnapshot>.broadcast();
  final Completer<TaskSnapshot> _done = Completer<TaskSnapshot>();

  @override
  Stream<TaskSnapshot> get snapshotEvents => events.stream;

  void fail(Object error) {
    events.addError(error);
    _done.completeError(error);
  }

  void succeed(TaskSnapshot snapshot) => _done.complete(snapshot);

  @override
  Future<R> then<R>(FutureOr<R> Function(TaskSnapshot) onValue,
          {Function? onError}) =>
      _done.future.then(onValue, onError: onError);

  @override
  Future<TaskSnapshot> catchError(Function onError,
          {bool Function(Object error)? test}) =>
      _done.future.catchError(onError, test: test);

  @override
  Future<TaskSnapshot> whenComplete(FutureOr<void> Function() action) =>
      _done.future.whenComplete(action);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReference implements Reference {
  final FakeUploadTask? task;
  final String? url;
  final List<String> paths;

  FakeReference({this.task, this.url, List<String>? paths})
      : paths = paths ?? [];

  @override
  Reference child(String path) {
    paths.add(path);
    return this;
  }

  @override
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) => task!;

  @override
  Future<String> getDownloadURL() async => url!;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStorage implements FirebaseStorage {
  final FakeReference reference;

  FakeStorage(this.reference);

  @override
  Reference ref([String? path]) => reference;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeUploadTask task;
  late FakeReference reference;
  late StorageService service;

  Future<String?> upload({void Function(double)? onProgress}) =>
      service.uploadReportPdf(
        uid: 'uid-a',
        fileName: 'e1.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
        onProgress: onProgress,
      );

  setUp(() {
    task = FakeUploadTask();
    reference = FakeReference(task: task);
    service = StorageService(storage: FakeStorage(reference));
  });

  test('a failed upload returns null, with no unhandled stream error', () async {
    final result = upload();
    await Future<void>.delayed(Duration.zero);

    task.fail(FirebaseException(plugin: 'firebase_storage', code: 'object-not-found'));

    expect(await result, isNull);
    await Future<void>.delayed(Duration.zero);
  });

  test('stops listening to progress after a failure', () async {
    final result = upload();
    await Future<void>.delayed(Duration.zero);
    expect(task.events.hasListener, isTrue);

    task.fail(Exception('network'));
    await result;

    expect(task.events.hasListener, isFalse);
  });

  test('reports progress and returns the URL, then stops listening', () async {
    final progress = <double>[];
    final result = upload(onProgress: progress.add);
    await Future<void>.delayed(Duration.zero);

    task.events.add(FakeSnapshot(1, 4));
    await Future<void>.delayed(Duration.zero);
    task.succeed(FakeSnapshot(4, 4, url: 'https://storage.test/e1.pdf'));

    expect(await result, 'https://storage.test/e1.pdf');
    expect(progress, [0.25]);
    expect(task.events.hasListener, isFalse);
    expect(reference.paths.single, 'reports/uid-a/e1.pdf');
  });
}
