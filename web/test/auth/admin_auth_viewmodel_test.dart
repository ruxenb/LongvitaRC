import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_admin/admin/admin_auth.dart';
import 'package:longvita_admin/admin/admin_auth_viewmodel.dart';

import 'auth_fakes.dart';

void main() {
  testWidgets('restore deadline has an error and explicit reconnect', (
    tester,
  ) async {
    final auth = _SilentAuth();
    final model = AdminAuthViewModel(auth);
    await tester.pump(const Duration(seconds: 16));
    expect(model.state.phase, AdminAuthPhase.authError);
    model.retryConnection();
    auth.emit(null);
    await tester.pump();
    expect(model.state.phase, AdminAuthPhase.signedOut);
    model.dispose();
    await auth.close();
  });

  testWidgets('logout deadline stays closed until late SDK confirmation', (
    tester,
  ) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    final done = Completer<void>();
    auth.logoutAction = () async {
      await done.future;
      auth.emit(null);
    };
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    final logout = model.signOut();
    await tester.pump(const Duration(seconds: 16));
    await logout;
    expect(model.state.phase, AdminAuthPhase.signOutError);
    expect(model.state.authorized, isFalse);
    done.complete();
    await tester.pump();
    expect(model.state.phase, AdminAuthPhase.signedOut);
    model.dispose();
    await auth.close();
  });

  testWidgets('disposed role request has no late notification or exception', (
    tester,
  ) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    final pending = Completer<String?>();
    auth.roleLoader = (_) => pending.future;
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    var calls = 0;
    model.addListener(() => calls++);
    model.dispose();
    pending.completeError(StateError('late-error'));
    await tester.pump();
    expect(calls, 0);
    expect(tester.takeException(), isNull);
    await auth.close();
  });

  testWidgets('real mutation queue prevents popup success after SDK logout', (
    tester,
  ) async {
    final auth = FakeAdminAuth();
    final popup = Completer<void>();
    final operations = AdminAuthMutations(
      login: () async {
        await popup.future;
        auth.emit(AuthTestUser('a'));
      },
      logout: () async {
        auth.emit(null);
      },
    );
    auth.googleAction = operations.signIn;
    auth.logoutAction = operations.signOut;
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    final login = model.signIn();
    final logout = model.signOut();
    popup.complete();
    await login;
    await logout;
    await tester.pump();
    expect(auth.currentUser, isNull);
    expect(model.state.phase, AdminAuthPhase.signedOut);
    expect(model.state.authorized, isFalse);
    model.dispose();
    await auth.close();
  });
  for (final role in <String?>['staff', 'admin', 'user', '', 'ADMIN', null]) {
    testWidgets('server role $role is allowed only for staff/admin', (
      tester,
    ) async {
      final auth = FakeAdminAuth()..user = AuthTestUser('a');
      auth.roleLoader = (_) async => role;
      final model = AdminAuthViewModel(auth);
      await tester.pump();
      expect(model.state.authorized, isAdminRole(role));
      expect(
        model.state.phase,
        isAdminRole(role) ? AdminAuthPhase.authorized : AdminAuthPhase.denied,
      );
      model.dispose();
      await auth.close();
    });
  }

  testWidgets('one role read for duplicate events in the same session', (
    tester,
  ) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    auth.emit(AuthTestUser('a'));
    await tester.pump();
    expect(auth.roleCalls, ['a']);
    model.dispose();
    await auth.close();
  });

  testWidgets('role timeout retries fresh and ignores the old success', (
    tester,
  ) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    final old = Completer<String?>();
    auth.roleLoader = (_) => old.future;
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    expect(model.state.phase, AdminAuthPhase.roleError);
    auth.roleLoader = (_) async => 'user';
    final invalidations = auth.invalidations;
    await model.retryRole();
    expect(auth.invalidations, greaterThan(invalidations));
    expect(model.state.phase, AdminAuthPhase.denied);
    old.complete('admin');
    await tester.pump();
    expect(model.state.authorized, isFalse);
    model.dispose();
    await auth.close();
  });

  testWidgets('A failure or success cannot replace B', (tester) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    final old = Completer<String?>();
    auth.roleLoader = (user) =>
        user.uid == 'a' ? old.future : Future.value('staff');
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    auth.emit(AuthTestUser('b'));
    await tester.pump();
    old.completeError(StateError('private-a'));
    await tester.pump();
    expect(model.state.user?.uid, 'b');
    expect(model.state.phase, AdminAuthPhase.authorized);
    expect(model.state.message, isNull);
    model.dispose();
    await auth.close();
  });

  testWidgets('A logout A uses a new session even without a frame for null', (
    tester,
  ) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    final old = Completer<String?>();
    auth.roleLoader = (_) => old.future;
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    final epoch = model.sessionGeneration;
    auth.emit(null);
    auth.emit(AuthTestUser('a'));
    auth.roleLoader = (_) async => null;
    await tester.pump();
    expect(model.sessionGeneration, greaterThan(epoch));
    old.complete('admin');
    await tester.pump();
    expect(model.state.phase, AdminAuthPhase.denied);
    expect(auth.roleCalls, ['a', 'a']);
    model.dispose();
    await auth.close();
  });

  testWidgets('double sign-in is blocked; cancellation has a safe message', (
    tester,
  ) async {
    final auth = FakeAdminAuth();
    final popup = Completer<void>();
    auth.googleAction = () => popup.future;
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    final first = model.signIn();
    await model.signIn();
    expect(auth.signIns, 1);
    expect(model.state.signingIn, isTrue);
    popup.completeError(FirebaseAuthException(code: 'popup-closed-by-user'));
    await first;
    expect(model.state.phase, AdminAuthPhase.signedOut);
    expect(model.state.signingIn, isFalse);
    expect(model.state.message, contains('hủy đăng nhập'));
    model.dispose();
    await auth.close();
  });

  testWidgets('user event before popup result loads role once', (tester) async {
    final auth = FakeAdminAuth();
    final popup = Completer<void>();
    auth.googleAction = () => popup.future;
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    final login = model.signIn();
    auth.emit(AuthTestUser('a'));
    await tester.pump();
    popup.complete();
    await login;
    await tester.pump();
    expect(model.state.authorized, isTrue);
    expect(auth.roleCalls, ['a']);
    model.dispose();
    await auth.close();
  });

  testWidgets(
    'popup result without another UID event still checks current user',
    (tester) async {
      final auth = FakeAdminAuth();
      auth.googleAction = () async {
        auth.user = AuthTestUser('a');
      };
      final model = AdminAuthViewModel(auth);
      await tester.pump();
      await model.signIn();
      await tester.pump();
      expect(model.state.authorized, isTrue);
      expect(auth.roleCalls, ['a']);
      model.dispose();
      await auth.close();
    },
  );

  testWidgets('logout hides the session immediately and rejects late roles', (
    tester,
  ) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    final role = Completer<String?>();
    final logout = Completer<void>();
    auth.roleLoader = (_) => role.future;
    auth.logoutAction = () async {
      await logout.future;
      auth.emit(null);
    };
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    final leaving = model.signOut();
    expect(model.state.phase, AdminAuthPhase.signingOut);
    expect(model.state.user, isNull);
    role.complete('admin');
    await tester.pump();
    expect(model.state.authorized, isFalse);
    logout.complete();
    await leaving;
    expect(model.state.phase, AdminAuthPhase.signedOut);
    model.dispose();
    await auth.close();
  });

  testWidgets('logout failure is visible, fail-closed, and retryable', (
    tester,
  ) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    auth.logoutAction = () async => throw StateError('private-error');
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    await model.signOut();
    expect(model.state.phase, AdminAuthPhase.signOutError);
    expect(model.state.message, isNot(contains('private-error')));
    auth.emit(AuthTestUser('a'));
    await tester.pump();
    expect(model.state.authorized, isFalse);
    await model.signIn();
    expect(auth.signIns, 0);
    auth.logoutAction = null;
    await model.signOut();
    expect(model.state.phase, AdminAuthPhase.signedOut);
    model.dispose();
    await auth.close();
  });

  testWidgets('old popup result cannot authorize after explicit logout', (
    tester,
  ) async {
    final auth = FakeAdminAuth();
    final popup = Completer<void>();
    auth.googleAction = () => popup.future;
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    final login = model.signIn();
    await model.signOut();
    auth.emit(AuthTestUser('a'));
    popup.complete();
    await login;
    await tester.pump();
    expect(model.state.phase, AdminAuthPhase.signedOut);
    expect(model.state.authorized, isFalse);
    model.dispose();
    await auth.close();
  });

  testWidgets('auth stream error revokes shell and supports reconnect', (
    tester,
  ) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    final model = AdminAuthViewModel(auth);
    await tester.pump();
    auth.changes.addError(StateError('private-stream'));
    await tester.pump();
    expect(model.state.phase, AdminAuthPhase.authError);
    expect(model.state.authorized, isFalse);
    model.retryConnection();
    await tester.pump();
    expect(model.state.authorized, isTrue);
    model.dispose();
    await auth.close();
  });

  test('SDK logout waits for a pending popup and blocks new sign-in', () async {
    final popup = Completer<void>();
    var sdkLogouts = 0;
    final operations = AdminAuthMutations(
      login: () => popup.future,
      logout: () async {
        sdkLogouts++;
      },
    );
    final login = operations.signIn();
    expect(identical(login, operations.signIn()), isTrue);
    final logout = operations.signOut();
    expect(sdkLogouts, 0);
    await expectLater(
      operations.signIn(),
      throwsA(isA<AdminAuthActionPending>()),
    );
    popup.complete();
    await login;
    await logout;
    expect(sdkLogouts, 1);
  });

  test(
    'cancelled popup still lets the queued SDK logout finish once',
    () async {
      final popup = Completer<void>();
      final logoutGate = Completer<void>();
      final started = Completer<void>();
      var count = 0;
      final operations = AdminAuthMutations(
        login: () => popup.future,
        logout: () async {
          count++;
          started.complete();
          await logoutGate.future;
        },
      );
      final login = operations.signIn();
      final checkLogin = expectLater(login, throwsA(isA<StateError>()));
      final first = operations.signOut();
      expect(identical(first, operations.signOut()), isTrue);
      popup.completeError(StateError('cancelled'));
      await checkLogin;
      await started.future;
      expect(count, 1);
      logoutGate.complete();
      await first;
    },
  );
}

class _SilentAuth extends FakeAdminAuth {
  @override
  Stream<User?> authStateChanges() => changes.stream;
}
