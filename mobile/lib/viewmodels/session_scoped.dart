import 'package:longvita_core/models/user_model.dart';

/// Implemented by ViewModels/services that hold data of the signed-in user.
///
/// `AuthViewModel` calls [clearSession] whenever the session ends (sign-out,
/// token revoked, or a different uid signs in) so user B never sees user A's
/// local state. Implementations drop in-memory data, cancel per-user
/// listeners and reset identifiers; they must not delete cloud records.
abstract interface class SessionScoped {
  /// Called once the profile of [user] is loaded.
  void onSessionStarted(UserModel user);

  /// Called when the session of the previous user ends.
  void clearSession();
}

/// Tells async work started in an earlier session apart from the current one.
///
/// [SessionScoped.clearSession] cannot cancel a running Future, so its result
/// would arrive in the next session. Capture [current] before the first await,
/// call [advance] in `clearSession`, and check [isStale] after every await.
/// This also covers the same uid signing back in, which a uid check would miss.
class SessionEpoch {
  int _value = 0;

  int get current => _value;

  void advance() => _value++;

  bool isStale(int captured) => captured != _value;
}
