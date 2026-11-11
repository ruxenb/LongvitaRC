import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:longvita_core/longvita_core.dart';

enum AnnouncementPhase {
  editing,
  sending,
  awaitingConfirmation,
  failed,
  published,
}

/// Owns the draft and one stable publish intent for this authorized session.
class AnnouncementViewModel extends ChangeNotifier {
  final IAnnouncementPublisher publisher;
  final String uid;
  final String role;
  final bool Function() sessionIsActive;
  final Future<void> Function() trackSuccessfulPublish;
  final DateTime Function() now;
  final Duration feedbackTimeout;
  bool _disposed = false;
  Timer? _timer;
  AnnouncementPublication? _publication;

  String title = '';
  String content = '';
  Set<String> targetRoles = {...AnnouncementModel.supportedTargetRoles};
  String? error;
  bool showValidation = false;
  AnnouncementPhase phase = AnnouncementPhase.editing;

  AnnouncementViewModel({
    required this.publisher,
    required this.uid,
    required this.role,
    required this.sessionIsActive,
    required this.trackSuccessfulPublish,
    DateTime Function()? now,
    this.feedbackTimeout = const Duration(seconds: 15),
  }) : now = now ?? DateTime.now;

  bool get busy =>
      phase == AnnouncementPhase.sending ||
      phase == AnnouncementPhase.awaitingConfirmation;
  bool get editable => phase == AnnouncementPhase.editing;
  bool get published => phase == AnnouncementPhase.published;
  String? get titleError =>
      showValidation ? AnnouncementPublication.titleError(title) : null;
  String? get contentError =>
      showValidation ? AnnouncementPublication.contentError(content) : null;

  void changeTitle(String value) {
    if (_disposed || !editable) return;
    title = value;
    notifyListeners();
  }

  void changeContent(String value) {
    if (_disposed || !editable) return;
    content = value;
    notifyListeners();
  }

  void toggleTargetRole(String role, bool selected) {
    if (_disposed ||
        !editable ||
        !AnnouncementModel.supportedTargetRoles.contains(role)) {
      return;
    }
    if (selected) {
      targetRoles.add(role);
    } else {
      targetRoles.remove(role);
    }
    notifyListeners();
  }

  bool validate() {
    if (_disposed || busy || published || !sessionIsActive()) return false;
    showValidation = true;
    notifyListeners();
    return titleError == null && contentError == null && targetRoles.isNotEmpty;
  }

  Future<void> publish() async {
    if (!validate()) return;
    phase = AnnouncementPhase.sending;
    error = null;
    notifyListeners();
    _timer = Timer(feedbackTimeout, () {
      if (_disposed || !sessionIsActive() || !busy) return;
      phase = AnnouncementPhase.awaitingConfirmation;
      notifyListeners();
    });
    try {
      _publication ??= AnnouncementPublication(
        uid: uid,
        announcement: AnnouncementModel(
          id: publisher.createId(),
          title: title.trim(),
          content: content.trim(),
          authorRole: role,
          targetRoles: targetRoles.toList(growable: false)..sort(),
          createdAt: now().toUtc(),
        ),
      );
      await publisher.publish(
        _publication!,
        sessionIsActive: () => !_disposed && sessionIsActive(),
      );
      if (_disposed || !sessionIsActive()) return;
      phase = AnnouncementPhase.published;
      notifyListeners();
      // A telemetry failure cannot turn a committed publication into a UI error.
      unawaited(
        Future<void>.sync(trackSuccessfulPublish).catchError((Object _) {}),
      );
    } catch (failure) {
      if (_disposed || !sessionIsActive()) return;
      phase = AnnouncementPhase.failed;
      error = DataFailure.from(failure).message;
      notifyListeners();
    } finally {
      _timer?.cancel();
      _timer = null;
    }
  }

  void startNew() {
    if (_disposed || !published || !sessionIsActive()) return;
    _publication = null;
    title = '';
    content = '';
    targetRoles = {...AnnouncementModel.supportedTargetRoles};
    error = null;
    showValidation = false;
    phase = AnnouncementPhase.editing;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
