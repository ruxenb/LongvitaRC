import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/services/auth_error_mapper.dart';

void main() {
  group('Google Sign-In', () {
    test('sign_in_canceled is a cancel', () {
      final f = AuthErrorMapper.fromGoogle(
          PlatformException(code: 'sign_in_canceled'));
      expect(f.kind, AuthFailureKind.cancelled);
    });

    test('network_error is network', () {
      final f =
          AuthErrorMapper.fromGoogle(PlatformException(code: 'network_error'));
      expect(f.kind, AuthFailureKind.network);
    });

    test('ApiException 10 (DEVELOPER_ERROR: SHA/package) is configuration',
        () {
      final f = AuthErrorMapper.fromGoogle(PlatformException(
        code: 'sign_in_failed',
        message: 'com.google.android.gms.common.api.ApiException: 10: ',
      ));
      expect(f.kind, AuthFailureKind.configuration);
      expect(f.code, 'sign_in_failed');
    });

    test('other sign_in_failed is a credential failure', () {
      final f = AuthErrorMapper.fromGoogle(PlatformException(
          code: 'sign_in_failed', message: 'ApiException: 8: '));
      expect(f.kind, AuthFailureKind.credential);
    });
  });

  group('Firebase Auth', () {
    test('network-request-failed is network', () {
      expect(
        AuthErrorMapper.fromFirebaseAuth(
                FirebaseAuthException(code: 'network-request-failed'))
            .kind,
        AuthFailureKind.network,
      );
    });

    test('operation-not-allowed (provider disabled) is configuration', () {
      expect(
        AuthErrorMapper.fromFirebaseAuth(
                FirebaseAuthException(code: 'operation-not-allowed'))
            .kind,
        AuthFailureKind.configuration,
      );
    });

    test('user-disabled / invalid-credential are credential', () {
      for (final code in ['user-disabled', 'invalid-credential']) {
        expect(
          AuthErrorMapper.fromFirebaseAuth(FirebaseAuthException(code: code))
              .kind,
          AuthFailureKind.credential,
          reason: code,
        );
      }
    });
  });

  group('Firestore profile', () {
    FirebaseException fs(String code) =>
        FirebaseException(plugin: 'cloud_firestore', code: code);

    test('permission-denied read is profileRead', () {
      final f =
          AuthErrorMapper.fromFirestore(fs('permission-denied'), writing: false);
      expect(f.kind, AuthFailureKind.profileRead);
      expect(f.isProfileFailure, isTrue);
    });

    test('permission-denied write is profileWrite', () {
      expect(
        AuthErrorMapper.fromFirestore(fs('permission-denied'), writing: true)
            .kind,
        AuthFailureKind.profileWrite,
      );
    });

    test('unavailable is network, not a cancelled sign-in', () {
      expect(
        AuthErrorMapper.fromFirestore(fs('unavailable'), writing: false).kind,
        AuthFailureKind.network,
      );
    });
  });
}
