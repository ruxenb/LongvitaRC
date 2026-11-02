import 'user_model.dart';

/// Why an authentication step did not complete. Each kind maps to a
/// different message and recovery in the UI.
enum AuthFailureKind {
  /// The user closed the Google account picker.
  cancelled,

  /// No connection or the backend was unreachable.
  network,

  /// App/Firebase/Google configuration problem (package name, SHA,
  /// OAuth client, missing google-services). Not fixable by the user.
  configuration,

  /// Google or Firebase rejected the credential (disabled account,
  /// invalid/expired token, provider conflict).
  credential,

  /// Signed in, but `users/{uid}` could not be read (rules, offline).
  profileRead,

  /// Signed in, but the first-sign-in `users/{uid}` document could not be
  /// written.
  profileWrite,

  /// Anything not classified above.
  unknown,
}

/// A classified auth error. [code] keeps the SDK code for logs/reports.
class AuthFailure implements Exception {
  final AuthFailureKind kind;
  final String? code;
  final Object? cause;

  const AuthFailure(this.kind, {this.code, this.cause});

  bool get isProfileFailure =>
      kind == AuthFailureKind.profileRead ||
      kind == AuthFailureKind.profileWrite;

  @override
  String toString() => 'AuthFailure($kind, code: $code, cause: $cause)';
}

/// Result of the Google + Firebase credential step. Loading the Longvita
/// profile is a separate step so a profile failure is never reported as a
/// cancelled sign-in.
sealed class AuthSignInResult {
  const AuthSignInResult();
}

class AuthSignInSucceeded extends AuthSignInResult {
  final String uid;
  const AuthSignInSucceeded(this.uid);
}

class AuthSignInCancelled extends AuthSignInResult {
  const AuthSignInCancelled();
}

class AuthSignInFailed extends AuthSignInResult {
  final AuthFailure failure;
  const AuthSignInFailed(this.failure);
}

/// Session state owned by `AuthViewModel` and read by the router.
sealed class AuthState {
  const AuthState();
}

/// Waiting for the first Firebase auth event after app start.
class AuthInitializing extends AuthState {
  const AuthInitializing();
}

/// No Firebase user. [notice] explains the last attempt (cancel/failure);
/// null after a normal start or sign-out.
class AuthSignedOut extends AuthState {
  final AuthFailure? notice;
  const AuthSignedOut({this.notice});
}

/// Google picker / credential exchange in progress.
class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

/// Firebase user exists; the `users/{uid}` profile is loading.
class AuthLoadingProfile extends AuthState {
  final String uid;
  const AuthLoadingProfile(this.uid);
}

/// Firebase user exists but the profile failed. The user can retry or sign
/// out; protected screens stay closed.
class AuthProfileError extends AuthState {
  final String uid;
  final AuthFailure failure;
  const AuthProfileError(this.uid, this.failure);
}

/// Signed in with a loaded profile.
class AuthSignedIn extends AuthState {
  final UserModel user;
  const AuthSignedIn(this.user);
}
