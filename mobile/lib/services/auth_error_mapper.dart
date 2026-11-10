import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'package:longvita_core/models/auth_state.dart';

/// Maps SDK exceptions to [AuthFailure]. Pure functions so the mapping is
/// unit-tested without Firebase.
class AuthErrorMapper {
  AuthErrorMapper._();

  /// `google_sign_in` (Android) reports through [PlatformException].
  /// `sign_in_failed` usually wraps ApiException 10 (DEVELOPER_ERROR: package
  /// name / SHA / OAuth client mismatch) or 12500.
  static AuthFailure fromGoogle(PlatformException e) {
    final code = e.code;
    final details = '${e.message ?? ''} ${e.details ?? ''}';
    if (code == 'sign_in_canceled' || details.contains('12501')) {
      return AuthFailure(AuthFailureKind.cancelled, code: code, cause: e);
    }
    if (code == 'network_error') {
      return AuthFailure(AuthFailureKind.network, code: code, cause: e);
    }
    if (code == 'sign_in_failed' &&
        (details.contains('ApiException: 10') || details.contains('12500'))) {
      return AuthFailure(AuthFailureKind.configuration, code: code, cause: e);
    }
    return AuthFailure(AuthFailureKind.credential, code: code, cause: e);
  }

  static AuthFailure fromFirebaseAuth(FirebaseAuthException e) {
    final kind = switch (e.code) {
      'network-request-failed' ||
      'too-many-requests' => AuthFailureKind.network,
      'operation-not-allowed' ||
      'app-not-authorized' ||
      'invalid-api-key' ||
      'unauthorized-domain' => AuthFailureKind.configuration,
      _ => AuthFailureKind.credential,
    };
    return AuthFailure(kind, code: e.code, cause: e);
  }

  /// Firestore errors on `users/{uid}`. [writing] selects profileWrite vs
  /// profileRead; connectivity problems become [AuthFailureKind.network] so
  /// the UI can suggest checking the connection.
  static AuthFailure fromFirestore(
    FirebaseException e, {
    required bool writing,
  }) {
    if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
      return AuthFailure(AuthFailureKind.network, code: e.code, cause: e);
    }
    return AuthFailure(
      writing ? AuthFailureKind.profileWrite : AuthFailureKind.profileRead,
      code: e.code,
      cause: e,
    );
  }
}
