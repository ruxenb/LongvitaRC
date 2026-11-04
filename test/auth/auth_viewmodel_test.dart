import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/models/user_model.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';

import 'auth_fakes.dart';

/// Profile loads that finish only when the test completes them, in any order.
class HeldProfileAuth extends FakeAuthService {
  HeldProfileAuth({super.initialUid});

  final requests = <Completer<UserModel>>[];

  @override
  Future<UserModel> loadProfile(String uid) {
    loadProfileCalls++;
    final request = Completer<UserModel>();
    requests.add(request);
    return request.future;
  }
}

UserModel named(String uid, String name) =>
    testUser(uid).copyWith(displayName: name);

/// Firebase reports the user before the sign-in call returns its result,
/// which each test releases in turn (PM-S3-5-06).
class EarlyUidAuth extends FakeAuthService {
  final results = <Completer<AuthSignInResult>>[];

  @override
  Future<AuthSignInResult> signInWithGoogle() {
    signInCalls++;
    emitUid((nextSignIn as AuthSignInSucceeded).uid);
    final result = Completer<AuthSignInResult>();
    results.add(result);
    return result.future;
  }
}

/// A telemetry call that finishes only when the test releases it.
class Held {
  final started = Completer<void>();
  final release = Completer<void>();

  Future<void> run() {
    started.complete();
    return release.future;
  }
}

class HeldCrashlytics extends FakeCrashlytics {
  final held = Held();

  @override
  Future<void> recordError(dynamic exception, StackTrace? stack,
      {dynamic reason, bool fatal = false}) {
    errors.add(exception);
    return held.run();
  }
}

class HeldAnalytics extends FakeAnalytics {
  Held? login;
  Held? logout;
  Object? logoutError;

  @override
  Future<void> logLogin({String method = 'google'}) {
    events.add('login:$method');
    return login?.run() ?? Future.value();
  }

  @override
  Future<void> logLogout() async {
    events.add('logout');
    if (logoutError != null) throw logoutError!;
    await logout?.run();
  }
}

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

  // PM-S3-5-03: loads were shared by uid only, so when Firebase reported no
  // user while a restored profile was loading and the same user signed back
  // in, the new session reused, and then accepted, the old load.
  group('a profile load belongs to the session it started in', () {
    late HeldProfileAuth held;

    /// Restored session of A with its profile load still pending, then
    /// Firebase reports no user and A signs in again.
    Future<AuthViewModel> reSignInDuringOldLoad({String again = 'uid-a'}) async {
      held = HeldProfileAuth(initialUid: 'uid-a');
      auth = held;
      final vm = build();
      await settle();
      expect(held.requests, hasLength(1));
      held.emitUid(null);
      await settle();
      expect(vm.state, isA<AuthSignedOut>());
      held.nextSignIn = AuthSignInSucceeded(again);
      unawaited(vm.signInWithGoogle());
      await settle();
      return vm;
    }

    test('same uid: the new session loads again and ignores the old result',
        () async {
      final vm = await reSignInDuringOldLoad();
      expect(held.requests, hasLength(2), reason: 'not reused across sessions');

      held.requests[0].complete(named('uid-a', 'old'));
      await settle();
      expect(vm.state, isA<AuthLoadingProfile>());
      expect(session.calls, isEmpty);

      held.requests[1].complete(named('uid-a', 'new'));
      await settle();
      expect(vm.currentUser?.displayName, 'new');
      expect(session.calls, ['start:uid-a']);
    });

    test('same uid: an old result arriving last changes nothing', () async {
      final vm = await reSignInDuringOldLoad();

      held.requests[1].complete(named('uid-a', 'new'));
      await settle();
      held.requests[0].complete(named('uid-a', 'old'));
      await settle();

      expect(vm.currentUser?.displayName, 'new');
      expect(session.calls, ['start:uid-a']);
    });

    test('same uid: an old failure is neither shown nor recorded', () async {
      final vm = await reSignInDuringOldLoad();

      held.requests[1].complete(named('uid-a', 'new'));
      await settle();
      held.requests[0].completeError(
          const AuthFailure(AuthFailureKind.profileRead));
      await settle();

      expect(vm.state, isA<AuthSignedIn>());
      expect(crashlytics.errors, isEmpty);
    });

    test('A then B: the old load of A is ignored', () async {
      final vm = await reSignInDuringOldLoad(again: 'uid-b');

      held.requests[0].complete(named('uid-a', 'old A'));
      held.requests[1].complete(named('uid-b', 'B'));
      await settle();

      expect(vm.currentUser?.uid, 'uid-b');
      expect(session.calls, ['start:uid-b']);
    });

    test('the end of an old load leaves the new one shared', () async {
      final vm = await reSignInDuringOldLoad();

      held.requests[0].complete(named('uid-a', 'old'));
      await settle();
      // The stream repeats the uid of the new session while it still loads.
      held.emitUid('uid-a');
      await settle();
      expect(held.requests, hasLength(2), reason: 'one load per session');

      held.requests[1].complete(named('uid-a', 'new'));
      await settle();
      expect(vm.currentUser?.displayName, 'new');
      expect(session.calls, ['start:uid-a']);
    });

    test('within one session the sign-in result and the stream share a load',
        () async {
      held = HeldProfileAuth();
      auth = held;
      final vm = build();
      await settle();
      held.nextSignIn = const AuthSignInSucceeded('uid-a');
      unawaited(vm.signInWithGoogle());
      await settle();

      expect(held.requests, hasLength(1));
      held.requests.single.complete(named('uid-a', 'A'));
      await settle();
      expect(vm.currentUser?.displayName, 'A');
    });
  });

  // PM-S3-5-03 (remaining) and PM-S3-5-05: the state used to change only after
  // an awaited Crashlytics or Analytics call, by which time another session
  // could have started. Telemetry now runs after the state change.
  group('telemetry finishing late does not change a newer session', () {
    late HeldProfileAuth held;
    late HeldCrashlytics heldCrash;
    late HeldAnalytics heldAnalytics;

    AuthViewModel buildHeld() {
      final vm = AuthViewModel(
        authService: held,
        analytics: heldAnalytics,
        crashlytics: heldCrash,
        sessionScoped: [session],
      );
      addTearDown(vm.dispose);
      return vm;
    }

    setUp(() {
      heldCrash = HeldCrashlytics();
      heldAnalytics = HeldAnalytics();
    });

    for (final (name, error) in [
      ('typed', const AuthFailure(AuthFailureKind.profileRead) as Object),
      ('generic', StateError('profile failed')),
    ]) {
      for (final next in ['uid-b', 'uid-a']) {
        test('$name profile error of A reported late: $next stays signed in',
            () async {
          held = HeldProfileAuth(initialUid: 'uid-a');
          final vm = buildHeld();
          await settle();
          held.requests.first.completeError(error);
          await heldCrash.held.started.future;
          expect(vm.state, isA<AuthProfileError>(),
              reason: 'shown while A is still current');

          held.emitUid(null);
          await settle();
          held.nextSignIn = AuthSignInSucceeded(next);
          final signIn = vm.signInWithGoogle();
          await settle();
          held.requests[1].complete(named(next, 'new'));
          await signIn;
          expect(vm.currentUser?.uid, next);

          heldCrash.held.release.complete();
          await settle();
          expect(vm.currentUser?.uid, next);
          expect(vm.currentUser?.displayName, 'new');
          expect(heldCrash.errors, [error], reason: 'still reported once');
        });
      }
    }

    for (final next in ['uid-b', 'uid-a']) {
      test('logout event of A finishing late: $next stays signed in', () async {
        held = HeldProfileAuth(initialUid: 'uid-a');
        final logout = heldAnalytics.logout = Held();
        final vm = buildHeld();
        await settle();
        held.requests.first.complete(named('uid-a', 'A'));
        await settle();

        final oldSignOut = vm.signOut();
        await logout.started.future;
        expect(vm.state, isA<AuthSignedOut>());

        held.nextSignIn = AuthSignInSucceeded(next);
        final signIn = vm.signInWithGoogle();
        await settle();
        held.requests[1].complete(named(next, 'new'));
        await signIn;
        expect(vm.currentUser?.uid, next);

        logout.release.complete();
        await oldSignOut;
        expect(vm.currentUser?.uid, next);
        expect(session.calls, ['start:uid-a', 'clear', 'start:$next']);
      });
    }

    test('login event finishing after logout does not load a profile again',
        () async {
      auth = FakeAuthService();
      final login = heldAnalytics.login = Held();
      final vm = AuthViewModel(
          authService: auth, analytics: heldAnalytics, crashlytics: heldCrash);
      addTearDown(vm.dispose);
      await settle();
      auth.nextSignIn = const AuthSignInSucceeded('uid-a');
      final oldSignIn = vm.signInWithGoogle();
      await login.started.future;
      await settle();
      expect(vm.currentUser?.uid, 'uid-a');

      await vm.signOut();
      await settle();
      final loads = auth.loadProfileCalls;

      login.release.complete();
      await oldSignIn;
      await settle();
      expect(vm.state, isA<AuthSignedOut>());
      expect(auth.loadProfileCalls, loads);
    });

    test('a pending login event does not block the next sign-in', () async {
      auth = FakeAuthService();
      final login = heldAnalytics.login = Held();
      final vm = AuthViewModel(
          authService: auth, analytics: heldAnalytics, crashlytics: heldCrash);
      addTearDown(vm.dispose);
      await settle();
      auth.nextSignIn = const AuthSignInSucceeded('uid-a');
      unawaited(vm.signInWithGoogle());
      await login.started.future;
      await settle();
      await vm.signOut();
      await settle();

      heldAnalytics.login = null;
      auth.nextSignIn = const AuthSignInSucceeded('uid-b');
      await vm.signInWithGoogle();
      await settle();

      expect(vm.currentUser?.uid, 'uid-b');
      login.release.complete();
      await settle();
      expect(vm.currentUser?.uid, 'uid-b');
    });

    test('a failed logout event is recorded and sign-out still completes',
        () async {
      auth = FakeAuthService(initialUid: 'uid-a');
      final analytics = HeldAnalytics()..logoutError = StateError('offline');
      final vm = AuthViewModel(
          authService: auth, analytics: analytics, crashlytics: crashlytics);
      addTearDown(vm.dispose);
      await settle();

      await vm.signOut();

      expect(vm.state, isA<AuthSignedOut>());
      expect(auth.currentUid, isNull);
      expect(crashlytics.errors.single, isA<StateError>());
    });
  });

  // PM-S3-5-06: the result of a sign-in that the user already left by signing
  // out was applied after the SDK call returned and started a profile load
  // with no Firebase user, which then stayed in loading.
  group('a sign-in result belongs to its attempt', () {
    late EarlyUidAuth early;

    Future<AuthViewModel> signedInByStream() async {
      early = EarlyUidAuth();
      auth = early;
      final vm = build();
      await settle();
      early.nextSignIn = const AuthSignInSucceeded('uid-a');
      unawaited(vm.signInWithGoogle());
      await settle();
      expect(vm.currentUser?.uid, 'uid-a', reason: 'in through the stream');
      return vm;
    }

    test('a result arriving after sign-out changes nothing', () async {
      final vm = await signedInByStream();
      await vm.signOut();
      await settle();
      final loads = early.loadProfileCalls;

      early.results.single.complete(const AuthSignInSucceeded('uid-a'));
      await settle();

      expect(vm.state, isA<AuthSignedOut>());
      expect(early.loadProfileCalls, loads);
      expect(analytics.events, isNot(contains('login:google')));
    });

    for (final next in ['uid-b', 'uid-a']) {
      test('an old result does not touch the next attempt ($next)', () async {
        final vm = await signedInByStream();
        await vm.signOut();
        await settle();

        early.nextSignIn = AuthSignInSucceeded(next);
        unawaited(vm.signInWithGoogle());
        await settle();
        expect(early.signInCalls, 2, reason: 'not blocked by the old attempt');

        early.results.first.complete(const AuthSignInSucceeded('uid-a'));
        await settle();
        // The new attempt is still in flight: a repeated tap stays ignored.
        unawaited(vm.signInWithGoogle());
        await settle();
        expect(early.signInCalls, 2);

        early.results.last.complete(AuthSignInSucceeded(next));
        await settle();
        expect(vm.currentUser?.uid, next);
        expect(session.calls.last, 'start:$next');
      });
    }

    test('a result after the stream signed in, same session, does not load '
        'again', () async {
      final vm = await signedInByStream();

      early.results.single.complete(const AuthSignInSucceeded('uid-a'));
      await settle();

      expect(vm.currentUser?.uid, 'uid-a');
      expect(early.loadProfileCalls, 1);
      expect(session.calls, ['start:uid-a']);
      expect(analytics.events, contains('login:google'));
    });

    test('a result while the stream load still runs shares it', () async {
      final heldAuth = HeldProfileAuth();
      auth = heldAuth;
      final vm = build();
      await settle();
      heldAuth.nextSignIn = const AuthSignInSucceeded('uid-a');

      final signIn = vm.signInWithGoogle();
      await settle();
      expect(heldAuth.requests, hasLength(1));
      heldAuth.requests.single.complete(named('uid-a', 'A'));
      await signIn;
      await settle();

      expect(vm.currentUser?.displayName, 'A');
      expect(heldAuth.loadProfileCalls, 1);
    });
  });
}
