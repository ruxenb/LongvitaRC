import 'package:longvita_core/models/auth_state.dart';
import 'package:longvita_core/models/user_model.dart';

/// Authentication contract (S2-1 / S3-3).
///
/// Signing in and loading the Longvita profile are separate steps so each
/// failure is reported as what it is:
/// - [signInWithGoogle] returns cancelled / failed / succeeded and never
///   throws for expected SDK errors.
/// - [loadProfile] reads or creates `users/{uid}` (role `user` on first
///   sign-in) and throws [AuthFailure] instead of returning null.
abstract class IAuthService {
  /// Firebase auth uid, or null when signed out. Emits the current value on
  /// listen.
  Stream<String?> get authUidChanges;

  /// Firebase auth uid right now, or null.
  String? get currentUid;

  /// Profile loaded by the last successful [loadProfile] for [currentUid].
  UserModel? get currentUser;

  Future<AuthSignInResult> signInWithGoogle();

  /// Throws [AuthFailure] (profileRead / profileWrite / network).
  Future<UserModel> loadProfile(String uid);

  /// Signs out of Google and Firebase. Never deletes cloud data.
  Future<void> signOut();
}
