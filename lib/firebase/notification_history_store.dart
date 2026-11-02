import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_notification.dart';

/// Keeps the notification history on this device, one file per user, under
/// `notifications/{uid}.json`. Temporary policy until the team agrees on one:
/// it stays after sign-out, so the same user finds it at the next sign-in.
///
/// Messages received in the background isolate wait in `pending.json`, because
/// that isolate does not know who is signed in.
class NotificationHistoryStore {
  static const maxEntries = 50;
  static const _pendingFile = 'pending';

  final Future<Directory> Function() _baseDirectory;

  NotificationHistoryStore({Future<Directory> Function()? baseDirectory})
      : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  /// Newest first. A missing or unreadable file is an empty history.
  Future<List<AppNotification>> load(String uid) async {
    _checkUid(uid);
    return _read(await _fileFor(uid));
  }

  /// Keeps the newest [maxEntries].
  Future<void> save(String uid, List<AppNotification> items) async {
    _checkUid(uid);
    await _write(await _fileFor(uid), items.take(maxEntries).toList());
  }

  Future<void> addPending(AppNotification item) async {
    final file = await _fileFor(_pendingFile);
    await _write(file, [item, ...await _read(file)].take(maxEntries).toList());
  }

  /// Returns the waiting messages, newest first, and clears them.
  Future<List<AppNotification>> takePending() async {
    final file = await _fileFor(_pendingFile);
    final items = await _read(file);
    if (await file.exists()) await file.delete();
    return items;
  }

  Future<File> _fileFor(String name) async {
    final base = await _baseDirectory();
    return File('${base.path}/notifications/$name.json');
  }

  Future<List<AppNotification>> _read(File file) async {
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      return decoded
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  /// Writes through a temporary file, so an interrupted write keeps the old one.
  Future<void> _write(File file, List<AppNotification> items) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
        jsonEncode(items.map((item) => item.toJson()).toList()),
        flush: true);
    await temp.rename(file.path);
  }

  /// A uid becomes a file name, and `pending` is reserved for waiting messages.
  static void _checkUid(String uid) {
    if (uid == _pendingFile || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(uid)) {
      throw ArgumentError.value(uid, 'uid', 'not a safe file name');
    }
  }
}
