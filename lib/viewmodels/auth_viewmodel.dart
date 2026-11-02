import 'dart:async';

import '../firebase/analytics_service.dart';
import '../firebase/crashlytics_service.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../services/i_auth_service.dart';
import 'base_viewmodel.dart';
import 'session_scoped.dart';

/// Owns the auth session state ([AuthState]) that `AuthGate` routes on.
///
/// - The Firebase auth stream is the source of truth for signed-in/out.
/// - A Firebase user only reaches [AuthSignedIn] after `users/{uid}` loads;
///   a profile failure becomes [AuthProfileError] with retry/sign-out
///   instead of being shown as a cancelled sign-in.
/// - Ending a session clears every [SessionScoped] participant and the
///   Analytics/Crashlytics user identifiers.
class AuthViewModel extends BaseViewModel {
  final IAuthService authService;
  final AnalyticsService analytics;
  final CrashlyticsService crashlytics;
  final List<SessionScoped> _sessionScoped;

  StreamSubscription<String?>? _authSubscription;
  AuthState _state = const AuthInitializing();

  /// Uid whose session data is currently held by participants.
  String? _sessionUid;

  /// Guards against overlapping profile loads for the same uid.
  Future<void>? _profileLoad;
  String? _profileLoadUid;

  /// Set while the Google picker is open so repeated taps are ignored.
  bool _signInInFlight = false;
  bool _signOutInFlight = false;

  AuthViewModel({
    required this.authService,
    required this.analytics,
    required this.crashlytics,
    Iterable<SessionScoped> sessionScoped = const [],
  }) : _sessionScoped = List.of(sessionScoped) {
    _authSubscription = authService.authUidChanges.listen(
      _onAuthUid,
      onError: (Object e, StackTrace s) {
        crashlytics.recordError(e, s, reason: 'Auth state stream error');
        _setState(AuthSignedOut(
            notice: AuthFailure(AuthFailureKind.unknown, cause: e)));
      },
    );
  }

  AuthState get state => _state;

  UserModel? get currentUser =>
      _state is AuthSignedIn ? (_state as AuthSignedIn).user : null;

  bool get isAuthenticated => _state is AuthSignedIn;

  /// True while a sign-in, profile load or sign-out is running.
  bool get isBusy =>
      _state is AuthSigningIn ||
      _state is AuthLoadingProfile ||
      _state is AuthInitializing;

  /// Registers a participant created after this ViewModel.
  void registerSessionScoped(SessionScoped participant) {
    _sessionScoped.add(participant);
    final user = currentUser;
    if (user != null) participant.onSessionStarted(user);
  }

  Future<void> signInWithGoogle() async {
    if (_signInInFlight || _state is! AuthSignedOut) return;
    _signInInFlight = true;
    _setState(const AuthSigningIn());

    try {
      final result = await authService.signInWithGoogle();
      switch (result) {
        case AuthSignInSucceeded(:final uid):
          await analytics.logLogin(method: 'google');
          // The auth stream also reports this uid; both paths share one load.
          await _loadProfile(uid);
        case AuthSignInCancelled():
          _setState(const AuthSignedOut(
              notice: AuthFailure(AuthFailureKind.cancelled)));
        case AuthSignInFailed(:final failure):
          await crashlytics.recordError(failure, StackTrace.current,
              reason: 'Google sign-in failed (${failure.kind.name})');
          _setState(AuthSignedOut(notice: failure));
      }
    } finally {
      _signInInFlight = false;
    }
  }

  /// Retries the profile load from [AuthProfileError].
  Future<void> retryProfile() async {
    final current = _state;
    if (current is AuthProfileError) await _loadProfile(current.uid);
  }

  Future<void> signOut() async {
    if (_signOutInFlight || _state is AuthInitializing) return;
    _signOutInFlight = true;
    try {
      await authService.signOut();
      await analytics.logLogout();
    } catch (e, s) {
      await crashlytics.recordError(e, s, reason: 'Sign-out failed');
    } finally {
      _signOutInFlight = false;
    }
    // Clear locally even if the SDK call failed: the user asked to leave.
    _endSession();
    _setState(const AuthSignedOut());
  }

  /// Dismisses the cancel/failure notice on the sign-in screen.
  void clearNotice() {
    if (_state case AuthSignedOut(notice: _?)) {
      _setState(const AuthSignedOut());
    }
  }

  void _onAuthUid(String? uid) {
    if (uid == null) {
      _endSession();
      // A signed-out state keeps its cancel/failure notice; an attempt in
      // progress reports its own outcome.
      if (_state is! AuthSignedOut && _state is! AuthSigningIn) {
        _setState(const AuthSignedOut());
      }
      return;
    }
    if (_sessionUid != null && _sessionUid != uid) _endSession();
    final current = _state;
    if (current is AuthSignedIn && current.user.uid == uid) return;
    _loadProfile(uid);
  }

  Future<void> _loadProfile(String uid) {
    if (_profileLoad != null && _profileLoadUid == uid) return _profileLoad!;
    _profileLoadUid = uid;
    return _profileLoad = _doLoadProfile(uid).whenComplete(() {
      if (_profileLoadUid == uid) {
        _profileLoad = null;
        _profileLoadUid = null;
      }
    });
  }

  Future<void> _doLoadProfile(String uid) async {
    _setState(AuthLoadingProfile(uid));
    try {
      final user = await authService.loadProfile(uid);
      if (authService.currentUid != uid) return; // signed out meanwhile
      _startSession(user);
      _setState(AuthSignedIn(user));
    } on AuthFailure catch (failure, s) {
      if (authService.currentUid != uid) return;
      await crashlytics.recordError(failure, s,
          reason: 'Profile load failed (${failure.kind.name})');
      _setState(AuthProfileError(uid, failure));
    } catch (e, s) {
      if (authService.currentUid != uid) return;
      await crashlytics.recordError(e, s, reason: 'Profile load failed');
      _setState(AuthProfileError(
          uid, AuthFailure(AuthFailureKind.unknown, cause: e)));
    }
  }

  void _startSession(UserModel user) {
    _sessionUid = user.uid;
    analytics.setUserId(user.uid);
    crashlytics.setUserId(user.uid);
    crashlytics.setCustomKey('user_role', user.role);
    for (final participant in _sessionScoped) {
      participant.onSessionStarted(user);
    }
  }

  void _endSession() {
    if (_sessionUid == null) return;
    _sessionUid = null;
    analytics.setUserId(null);
    crashlytics.setUserId('');
    crashlytics.setCustomKey('user_role', 'signed_out');
    for (final participant in _sessionScoped) {
      participant.clearSession();
    }
  }

  void _setState(AuthState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
