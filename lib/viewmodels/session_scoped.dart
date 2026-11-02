import '../models/user_model.dart';

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
