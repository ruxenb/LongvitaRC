import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_notification.dart';

/// A background message waiting on the device for its recipient to open the
/// app. [ref] names its file; pass the entry back to
/// [NotificationHistoryStore.ackPending] once it is safely in the history.
class PendingNotification {
  final AppNotification notification;
  final String ref;

  const PendingNotification(this.notification, this.ref);
}

/// Keeps the notification history on this device, one file per user, under
/// `notifications/{uid}.json`, at most [maxEntries] each. It stays after
/// sign-out, so the same user finds it at the next sign-in.
///
/// Messages received in the background isolate wait in `notifications/pending/`,
/// one file per message, because that isolate does not know who is signed in.
/// Each writer only creates its own new file, so the background isolate adding
/// a message while the app reads the queue loses nothing. The app claims only
/// the messages of the signed-in user and removes them after they are saved;
/// messages of other users stay until their owner signs in. File names are
/// generated, never taken from a message id or uid.
class NotificationHistoryStore {
  static const maxEntries = 50;

  /// Waiting messages kept for all users together; the oldest go first.
  static const maxPending = 50;

  static const _pendingDir = 'pending';

  /// The single queue file of earlier versions, read once and replaced.
  static const _legacyPendingFile = 'pending';

  static final _random = Random.secure();
  static final _pendingName = RegExp(r'^\d{16}-[0-9a-f]{8}\.json$');
  static final Map<String, Future<void>> _migrationTasks = {};

  final Future<Directory> Function() _baseDirectory;
  final Future<String> Function(File file) _readFile;

  NotificationHistoryStore({
    Future<Directory> Function()? baseDirectory,
    @visibleForTesting Future<String> Function(File file)? readFile,
  }) : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory,
       _readFile = readFile ?? ((file) => file.readAsString());

  /// Newest first. A missing file is an empty history; a file that is not
  /// valid JSON reads as empty, and an unreadable entry is skipped. A file
  /// that exists but cannot be read throws, so the caller does not mistake it
  /// for an empty history and replace it. Entries are returned as saved; the
  /// inbox decides which belong to the user.
  Future<List<AppNotification>> load(String uid) async {
    _checkUid(uid);
    return _readList(await _fileFor(uid));
  }

  /// Keeps the newest [maxEntries].
  Future<void> save(String uid, List<AppNotification> items) async {
    _checkUid(uid);
    await _writeList(await _fileFor(uid), items.take(maxEntries).toList());
  }

  /// Queues a background message. A message with no valid recipient is not
  /// kept, since nobody may see it.
  Future<void> addPending(AppNotification item) async {
    if (item.recipientUid == null) return;
    final dir = await _pendingDirectory();
    await dir.create(recursive: true);
    final nonce = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final name = '${_nextStamp().toString().padLeft(16, '0')}-$nonce.json';
    // Written under a name readers skip, then renamed into place whole.
    final temp = File('${dir.path}/$name.tmp');
    await temp.writeAsString(jsonEncode(item.toJson()), flush: true);
    await temp.rename('${dir.path}/$name');
    await _prunePending(dir);
  }

  /// The waiting messages for [uid], oldest first, without removing them.
  /// Messages of other users and unreadable files are left alone.
  Future<List<PendingNotification>> claimPending(String uid) async {
    _checkUid(uid);
    await _migrateLegacyPending();
    final claimed = <PendingNotification>[];
    for (final file in await _pendingFiles()) {
      final item = await _readOne(file);
      if (item != null && item.isFor(uid)) {
        claimed.add(PendingNotification(item, _baseName(file)));
      }
    }
    return claimed;
  }

  /// Removes claimed messages once they are in the history. A file already
  /// gone (claimed twice, or pruned) is not an error.
  Future<void> ackPending(List<PendingNotification> entries) async {
    final dir = await _pendingDirectory();
    for (final entry in entries) {
      if (!_pendingName.hasMatch(entry.ref)) continue;
      try {
        await File('${dir.path}/${entry.ref}').delete();
      } on FileSystemException {
        // Already removed.
      }
    }
  }

  Future<File> _fileFor(String name) async {
    final base = await _baseDirectory();
    return File('${base.path}/notifications/$name.json');
  }

  Future<Directory> _pendingDirectory() async {
    final base = await _baseDirectory();
    return Directory('${base.path}/notifications/$_pendingDir');
  }

  /// Queue files, oldest first (names start with a fixed-width time).
  Future<List<File>> _pendingFiles() async {
    final dir = await _pendingDirectory();
    if (!await dir.exists()) return const [];
    final files = <File>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File && _pendingName.hasMatch(_baseName(entity))) {
        files.add(entity);
      }
    }
    files.sort((a, b) => _baseName(a).compareTo(_baseName(b)));
    return files;
  }

  Future<void> _prunePending(Directory dir) async {
    final files = await _pendingFiles();
    for (final file in files.take(max(0, files.length - maxPending))) {
      try {
        await file.delete();
      } on FileSystemException {
        // Removed by another writer.
      }
    }
  }

  /// Moves recipients' messages from the old single queue file into the new
  /// queue and removes it. Its entries with no valid recipient are not moved:
  /// under v1 nobody may see them. Only the app isolate reads that file now.
  /// A read that fails throws before anything is removed.
  Future<void> _migrateLegacyPending() async {
    final legacy = await _fileFor(_legacyPendingFile);
    final key = legacy.absolute.path;
    final previous = _migrationTasks[key] ?? Future<void>.value();
    final next = previous.then((_) => _resumeLegacyMigration(legacy));
    // Keep an error-free barrier: a failed migration must be retryable.
    late final Future<void> barrier;
    void release() {
      if (identical(_migrationTasks[key], barrier)) _migrationTasks.remove(key);
    }

    barrier = next.then<void>(
      (_) => release(),
      onError: (Object e, StackTrace stack) => release(),
    );
    _migrationTasks[key] = barrier;
    return next;
  }

  Future<void> _resumeLegacyMigration(File legacy) async {
    final manifest = File('${legacy.parent.path}/pending.migration.json');
    if (!await manifest.exists()) {
      if (!await legacy.exists()) return;
      final items = (await _readList(legacy))
          .where((item) => item.recipientUid != null)
          .take(maxPending)
          .toList();
      final files = await _pendingFiles();
      var oldest = (await legacy.lastModified()).microsecondsSinceEpoch;
      if (files.isNotEmpty) {
        oldest = min(
          oldest,
          int.parse(_baseName(files.first).split('-').first),
        );
      }
      // Legacy entries predate the per-message queue. Preserve that age when
      // applying the shared capacity limit, including across retries.
      if (oldest <= items.length) {
        throw const FormatException('Invalid legacy queue timestamp');
      }
      final entries = <Map<String, Object>>[];
      var stamp = oldest - items.length;
      for (final item in items.reversed) {
        final nonce = _random
            .nextInt(1 << 32)
            .toRadixString(16)
            .padLeft(8, '0');
        entries.add({
          'ref': '${(stamp++).toString().padLeft(16, '0')}-$nonce.json',
          'item': item.toJson(),
        });
      }
      // Persist stable names BEFORE importing anything. An interruption then
      // resumes these same files rather than duplicating legacy messages.
      await manifest.parent.create(recursive: true);
      final temp = File('${manifest.path}.tmp');
      await temp.writeAsString(jsonEncode(entries), flush: true);
      await temp.rename(manifest.path);
    }
    final decoded = jsonDecode(await _readFile(manifest));
    if (decoded is! List || decoded.length > maxPending) {
      throw const FormatException('Invalid legacy migration manifest');
    }
    final entries = <PendingNotification>[];
    final refs = <String>{};
    for (final entry in decoded) {
      final ref = entry is Map ? entry['ref'] : null;
      final item = entry is Map
          ? AppNotification.tryFromJson(entry['item'])
          : null;
      if (ref is! String ||
          !_pendingName.hasMatch(ref) ||
          !refs.add(ref) ||
          item?.recipientUid == null) {
        throw const FormatException('Invalid legacy migration entry');
      }
      entries.add(PendingNotification(item!, ref));
    }
    final dir = await _pendingDirectory();
    await dir.create(recursive: true);
    for (final entry in entries) {
      final file = File('${dir.path}/${entry.ref}');
      if (await file.exists()) continue;
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(
        jsonEncode(entry.notification.toJson()),
        flush: true,
      );
      await temp.rename(file.path);
    }
    await _prunePending(dir);
    // Keep the checkpoint until the original is gone. If either operation
    // fails, the next attempt reuses the same names and chronological order.
    if (await legacy.exists()) await legacy.delete();
    await manifest.delete();
  }

  Future<List<AppNotification>> _readList(File file) async {
    if (!await file.exists()) return const [];
    final String text;
    try {
      text = await _readFile(file);
    } on FileSystemException {
      // Gone since the check: nothing saved. Still there: a read error.
      if (!await file.exists()) return const [];
      rethrow;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return const [];
      return decoded
          .map(AppNotification.tryFromJson)
          .whereType<AppNotification>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  /// One queued message, or null when it cannot be read now. It is then not
  /// claimed, so it is not removed either, and a later drain tries again.
  Future<AppNotification?> _readOne(File file) async {
    try {
      return AppNotification.tryFromJson(jsonDecode(await _readFile(file)));
    } on FormatException {
      return null;
    } on FileSystemException {
      return null; // Removed meanwhile.
    }
  }

  /// Writes through a temporary file, so an interrupted write keeps the old one.
  Future<void> _writeList(File file, List<AppNotification> items) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      jsonEncode(items.map((item) => item.toJson()).toList()),
      flush: true,
    );
    await temp.rename(file.path);
  }

  static int _lastStamp = 0;

  /// Microseconds since the epoch, increasing within this isolate even when
  /// the clock repeats a value, so queue order follows the order of adds.
  static int _nextStamp() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastStamp = now > _lastStamp ? now : _lastStamp + 1;
    return _lastStamp;
  }

  static String _baseName(File file) => file.uri.pathSegments.last;

  /// A uid becomes a file name, and `pending` is reserved for waiting messages.
  static void _checkUid(String uid) {
    if (uid == _pendingDir || !recipientUidPattern.hasMatch(uid)) {
      throw ArgumentError.value(uid, 'uid', 'not a safe file name');
    }
  }
}
