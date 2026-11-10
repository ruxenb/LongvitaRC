// A failed upload also fails the progress stream. Without an error handler that
// stream raises an unhandled exception, which fails these tests through the
// test zone. This was first seen on Android as firebase_storage/object-not-found.
import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/storage_service.dart';
import 'package:longvita_core/models/upload_failure.dart';

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

  int cancelCalls = 0;

  /// Like the SDK, a cancelled task fails with the code `canceled`.
  @override
  Future<bool> cancel() async {
    cancelCalls++;
    fail(FirebaseException(plugin: 'firebase_storage', code: 'canceled'));
    return true;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(TaskSnapshot) onValue, {
    Function? onError,
  }) => _done.future.then(onValue, onError: onError);

  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _done.future.catchError(onError, test: test);

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
  int refCalls = 0;

  FakeStorage(this.reference);

  @override
  Reference ref([String? path]) {
    refCalls++;
    return reference;
  }

  @override
  void setMaxUploadRetryTime(Duration time) {}

  @override
  Future<void> useStorageEmulator(
    String host,
    int port, {
    bool automaticHostMapping = true,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class HeldEmulatorStorage extends FakeStorage {
  final configured = Completer<void>();
  HeldEmulatorStorage(super.reference);
  @override
  Future<void> useStorageEmulator(
    String host,
    int port, {
    bool automaticHostMapping = true,
  }) => configured.future;
}

void main() {
  late FakeUploadTask task;
  late FakeReference reference;
  late StorageService service;

  Future<String> upload({void Function(double)? onProgress}) =>
      service.uploadReportPdf(
        uid: 'uid-a',
        fileName: 'e1.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
        onProgress: onProgress,
      );

  setUp(() {
    task = FakeUploadTask();
    reference = FakeReference(task: task);
    service = StorageService(
      storage: FakeStorage(reference),
      emulatorHost: 'localhost',
    );
  });

  test('does not access Storage until emulator setup succeeds', () async {
    final sdk = HeldEmulatorStorage(reference);
    service = StorageService(storage: sdk, emulatorHost: 'localhost');
    final result = upload();
    expect(sdk.refCalls, 0);
    sdk.configured.complete();
    // A turn of the event loop flushes the ready Future, not a fixed delay.
    await Future<void>.delayed(Duration.zero);
    expect(sdk.refCalls, 1);
    task.succeed(FakeSnapshot(3, 3, url: 'http://localhost/e1.pdf'));
    expect(await result, 'http://localhost/e1.pdf');
  });

  test('failed setup never falls back to production Storage', () async {
    final sdk = HeldEmulatorStorage(reference);
    service = StorageService(storage: sdk, emulatorHost: 'localhost');
    sdk.configured.completeError(StateError('setup failed'));
    await Future<void>.delayed(Duration.zero);
    await expectLater(
      upload(),
      throwsA(
        isA<UploadFailure>().having(
          (e) => e.kind,
          'kind',
          UploadFailureKind.notConfigured,
        ),
      ),
    );
    expect(sdk.refCalls, 0);
  });

  test('cancel during setup prevents a late upload from starting', () async {
    final sdk = HeldEmulatorStorage(reference);
    service = StorageService(storage: sdk, emulatorHost: 'localhost');
    final result = upload();
    final check = expectLater(
      result,
      throwsA(
        isA<UploadFailure>().having(
          (e) => e.kind,
          'kind',
          UploadFailureKind.cancelled,
        ),
      ),
    );
    await service.cancelActiveUpload();
    sdk.configured.complete();
    await check;
    expect(sdk.refCalls, 0);
  });

  test(
    'adapter rejects remote or missing hosts before obtaining an SDK instance',
    () {
      for (final host in ['', 'storage.googleapis.com', 'localhost.evil']) {
        expect(() => StorageService(emulatorHost: host), throwsArgumentError);
      }
    },
  );

  group('a failed upload', () {
    for (final (code, kind) in const [
      ('canceled', UploadFailureKind.cancelled),
      ('unauthorized', UploadFailureKind.denied),
      ('unauthenticated', UploadFailureKind.denied),
      ('retry-limit-exceeded', UploadFailureKind.network),
      ('quota-exceeded', UploadFailureKind.quota),
      ('object-not-found', UploadFailureKind.notConfigured),
      ('bucket-not-found', UploadFailureKind.notConfigured),
      ('project-not-found', UploadFailureKind.notConfigured),
      ('something-new', UploadFailureKind.unknown),
    ]) {
      test(
        '$code becomes ${kind.name}, with no unhandled stream error',
        () async {
          final result = upload();
          await Future<void>.delayed(Duration.zero);

          task.fail(FirebaseException(plugin: 'firebase_storage', code: code));

          await expectLater(
            result,
            throwsA(
              isA<UploadFailure>()
                  .having((f) => f.kind, 'kind', kind)
                  .having((f) => f.code, 'code', code),
            ),
          );
          await Future<void>.delayed(Duration.zero);
        },
      );
    }

    test('an error from outside Firebase becomes unknown', () async {
      final result = upload();
      await Future<void>.delayed(Duration.zero);

      task.fail(Exception('boom'));

      await expectLater(
        result,
        throwsA(
          isA<UploadFailure>().having(
            (f) => f.kind,
            'kind',
            UploadFailureKind.unknown,
          ),
        ),
      );
    });
  });

  group('cancelActiveUpload', () {
    test('cancels the running task', () async {
      final result = upload();
      await Future<void>.delayed(Duration.zero);

      await service.cancelActiveUpload();

      expect(task.cancelCalls, 1);
      await expectLater(
        result,
        throwsA(
          isA<UploadFailure>().having(
            (f) => f.kind,
            'kind',
            UploadFailureKind.cancelled,
          ),
        ),
      );
    });

    test('does nothing after the upload ended', () async {
      final result = upload();
      await Future<void>.delayed(Duration.zero);
      task.succeed(FakeSnapshot(4, 4, url: 'https://storage.test/e1.pdf'));
      await result;

      await service.cancelActiveUpload();

      expect(task.cancelCalls, 0);
    });

    test('does nothing with no upload', () async {
      await service.cancelActiveUpload();

      expect(task.cancelCalls, 0);
    });
  });

  test('stops listening to progress after a failure', () async {
    final result = upload();
    await Future<void>.delayed(Duration.zero);
    expect(task.events.hasListener, isTrue);

    task.fail(Exception('network'));
    await expectLater(result, throwsA(isA<UploadFailure>()));

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
