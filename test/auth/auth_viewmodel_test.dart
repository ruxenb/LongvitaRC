import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';

import 'auth_fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeAnalytics analytics;
  late FakeCrashlytics crashlytics;
  late RecordingSession session;

  AuthViewModel build() => AuthViewModel(
        authService: auth,
        analytics: analytics,
        crashlytics: crashlytics,
        sessionScoped: [session],
      );

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

  setUp(() {
    auth = FakeAuthService();
    analytics = FakeAnalytics();
    crashlytics = FakeCrashlytics();
    session = RecordingSession();
  });

  test('starts in Initializing, then SignedOut without a notice', () async {
    final vm = build();
    expect(vm.state, isA<AuthInitializing>());
    await settle();
    expect(vm.state, isA<AuthSignedOut>());
    expect((vm.state as AuthSignedOut).notice, isNull);
    expect(vm.isAuthenticated, isFalse);
  });

  test('success: credential then profile, session started, ids set', () async {
    final vm = build();
    await settle();
    auth.nextSignIn = const AuthSignInSucceeded('uid-a');

    await vm.signInWithGoogle();
    await settle();

    expect(vm.state, isA<AuthSignedIn>());
    expect(vm.currentUser?.uid, 'uid-a');
    expect(auth.loadProfileCalls, 1, reason: 'stream + result share one load');
    expect(session.calls, ['start:uid-a']);
    expect(analytics.userIds, ['uid-a']);
    expect(analytics.events, contains('login:google'));
    expect(crashlytics.userIds, ['uid-a']);
  });

  test('cancel: SignedOut with cancelled notice, no profile load', () async {
    final vm = build();
    await settle();
    auth.nextSignIn = const AuthSignInCancelled();

    await vm.signInWithGoogle();

    final state = vm.state as AuthSignedOut;
    expect(state.notice?.kind, AuthFailureKind.cancelled);
    expect(auth.loadProfileCalls, 0);
    expect(crashlytics.errors, isEmpty, reason: 'cancel is not an error');
    vm.clearNotice();
    expect((vm.state as AuthSignedOut).notice, isNull);
  });

  test('credential failure: SignedOut with its kind, recorded non-fatal',
      () async {
    final vm = build();
    await settle();
    auth.nextSignIn = const AuthSignInFailed(
        AuthFailure(AuthFailureKind.credential, code: 'user-disabled'));

    await vm.signInWithGoogle();

    final state = vm.state as AuthSignedOut;
    expect(state.notice?.kind, AuthFailureKind.credential);
    expect(crashlytics.errors.single, isA<AuthFailure>());
  });

  test('profile failure after sign-in is ProfileError, not cancel; retry works',
      () async {
    final vm = build();
    await settle();
    auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    auth.profileResults
        .add(const AuthFailure(AuthFailureKind.profileRead, code: 'permission-denied'));

    await vm.signInWithGoogle();
    await settle();

    expect(vm.state, isA<AuthProfileError>());
    final error = vm.state as AuthProfileError;
    expect(error.uid, 'uid-a');
    expect(error.failure.kind, AuthFailureKind.profileRead);
    expect(vm.isAuthenticated, isFalse, reason: 'protected content stays closed');
    expect(session.calls, isEmpty);

    await vm.retryProfile();
    expect(vm.state, isA<AuthSignedIn>());
    expect(session.calls, ['start:uid-a']);
  });

  test('profile failure can sign out instead of retrying', () async {
    final vm = build();
    await settle();
    auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    auth.profileResults.add(const AuthFailure(AuthFailureKind.profileWrite));
    await vm.signInWithGoogle();
    await settle();
    expect(vm.state, isA<AuthProfileError>());

    await vm.signOut();
    expect(vm.state, isA<AuthSignedOut>());
    expect(auth.signOutCalls, 1);
  });

  test('repeated taps while the picker is open start one sign-in', () async {
    final vm = build();
    await settle();
    auth.pendingSignIn = Completer<AuthSignInResult>();

    final first = vm.signInWithGoogle();
    final second = vm.signInWithGoogle();
    expect(vm.state, isA<AuthSigningIn>());
    expect(vm.isBusy, isTrue);

    auth.pendingSignIn!.complete(const AuthSignInCancelled());
    await Future.wait([first, second]);
    expect(auth.signInCalls, 1);
  });

  test('restored session loads the profile without a new sign-in', () async {
    auth = FakeAuthService(initialUid: 'uid-a');
    final vm = build();
    await settle();
    expect(vm.state, isA<AuthSignedIn>());
    expect(auth.signInCalls, 0);
  });

  test('logout clears session data and identifiers, keeps cloud data',
      () async {
    final vm = build();
    await settle();
    auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    await vm.signInWithGoogle();
    await settle();

    await vm.signOut();
    await settle();

    expect(vm.state, isA<AuthSignedOut>());
    expect(vm.currentUser, isNull);
    expect(session.calls, ['start:uid-a', 'clear'],
        reason: 'cleared exactly once even though the stream also emits null');
    expect(analytics.userIds.last, isNull);
    expect(crashlytics.userIds.last, '');
    expect(analytics.events, contains('logout'));
  });

  test('sign-out SDK failure still clears local session', () async {
    final vm = build();
    await settle();
    auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    await vm.signInWithGoogle();
    await settle();
    auth.failSignOut = true;

    await vm.signOut();

    expect(vm.state, isA<AuthSignedOut>());
    expect(session.calls.last, 'clear');
    expect(crashlytics.errors, isNotEmpty);
  });

  test('user B replacing user A clears A before starting B', () async {
    final vm = build();
    await settle();
    auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    await vm.signInWithGoogle();
    await settle();

    auth.emitUid('uid-b');
    await settle();

    expect(vm.currentUser?.uid, 'uid-b');
    expect(session.calls, ['start:uid-a', 'clear', 'start:uid-b']);
  });

  test('token revoked (stream emits null) ends the session', () async {
    auth = FakeAuthService(initialUid: 'uid-a');
    final vm = build();
    await settle();

    auth.emitUid(null);
    await settle();

    expect(vm.state, isA<AuthSignedOut>());
    expect(session.calls, ['start:uid-a', 'clear']);
  });
}
