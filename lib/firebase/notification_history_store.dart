import 'dart:convert';
import 'dart:io';
import 'dart:math';

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

  final Future<Directory> Function() _baseDirectory;

  NotificationHistoryStore({Future<Directory> Function()? baseDirectory})
      : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  /// Newest first. A missing or unreadable file is an empty history, and an
  /// unreadable entry is skipped. Entries are returned as saved; the inbox
  /// decides which belong to the user.
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
  Future<void> _migrateLegacyPending() async {
    final legacy = await _fileFor(_legacyPendingFile);
    if (!await legacy.exists()) return;
    final items = await _readList(legacy);
    for (final item in items.reversed) {
      await addPending(item);
    }
    try {
      await legacy.delete();
    } on FileSystemException {
      // Another drain moved it first.
    }
  }

  Future<List<AppNotification>> _readList(File file) async {
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return decoded
          .map(AppNotification.tryFromJson)
          .whereType<AppNotification>()
          .toList();
    } on FormatException {
      return const [];
    } on FileSystemException {
      return const [];
    }
  }

  Future<AppNotification?> _readOne(File file) async {
    try {
      return AppNotification.tryFromJson(jsonDecode(await file.readAsString()));
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
        flush: true);
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
