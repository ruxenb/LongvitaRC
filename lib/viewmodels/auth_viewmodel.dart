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

  /// Changes whenever a session ends: Firebase reports no user or another
  /// user, or sign-out starts. A profile load belongs to the value it started
  /// under, so the same uid signing back in neither reuses nor accepts the
  /// load of the ended session (PM-S3-5-03).
  int _authGeneration = 0;
  String? _lastStreamUid;

  /// One profile load per uid and session: the sign-in result and the auth
  /// stream both ask for it.
  Future<void>? _profileLoad;
  String? _profileLoadUid;
  int? _profileLoadGeneration;

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

    final AuthSignInResult result;
    try {
      result = await authService.signInWithGoogle();
    } finally {
      // The picker is closed; a later attempt must not wait for telemetry.
      _signInInFlight = false;
    }
    // State changes first, while this attempt is still current; reporting
    // comes after and never decides the session (PM-S3-5-05).
    switch (result) {
      case AuthSignInSucceeded(:final uid):
        // The auth stream also reports this uid; both paths share one load.
        final load = _loadProfile(uid);
        await _sendTelemetry(() => analytics.logLogin(method: 'google'),
            reason: 'Login event failed');
        await load;
      case AuthSignInCancelled():
        _setState(const AuthSignedOut(
            notice: AuthFailure(AuthFailureKind.cancelled)));
      case AuthSignInFailed(:final failure):
        _setState(AuthSignedOut(notice: failure));
        await crashlytics.recordError(failure, StackTrace.current,
            reason: 'Google sign-in failed (${failure.kind.name})');
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
    final generation = ++_authGeneration;
    Object? error;
    StackTrace? errorStack;
    try {
      await authService.signOut();
    } catch (e, s) {
      error = e;
      errorStack = s;
    } finally {
      _signOutInFlight = false;
    }
    // Clear locally even if the SDK call failed: the user asked to leave. Not
    // when a newer session began meanwhile, which the auth stream reports
    // after ending this one (PM-S3-5-05).
    if (generation == _authGeneration) {
      _endSession();
      _setState(const AuthSignedOut());
    }
    if (error != null) {
      await crashlytics.recordError(error, errorStack,
          reason: 'Sign-out failed');
    } else {
      await _sendTelemetry(analytics.logLogout, reason: 'Logout event failed');
    }
  }

  /// Dismisses the cancel/failure notice on the sign-in screen.
  void clearNotice() {
    if (_state case AuthSignedOut(notice: _?)) {
      _setState(const AuthSignedOut());
    }
  }

  void _onAuthUid(String? uid) {
    final previous = _lastStreamUid;
    _lastStreamUid = uid;
    if (uid == null || (previous != null && previous != uid)) {
      _authGeneration++;
    }
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
    final generation = _authGeneration;
    final pending = _profileLoad;
    if (pending != null &&
        _profileLoadUid == uid &&
        _profileLoadGeneration == generation) {
      return pending;
    }
    late final Future<void> load;
    load = _doLoadProfile(uid, generation).whenComplete(() {
      // A newer load may have replaced this one; leave its handle alone.
      if (identical(_profileLoad, load)) {
        _profileLoad = null;
        _profileLoadUid = null;
        _profileLoadGeneration = null;
      }
    });
    _profileLoad = load;
    _profileLoadUid = uid;
    _profileLoadGeneration = generation;
    return load;
  }

  /// False once the session the load started in has ended, or the user changed.
  bool _isCurrentLoad(String uid, int generation) =>
      generation == _authGeneration && authService.currentUid == uid;

  Future<void> _doLoadProfile(String uid, int generation) async {
    _setState(AuthLoadingProfile(uid));
    try {
      final user = await authService.loadProfile(uid);
      if (!_isCurrentLoad(uid, generation)) return;
      _startSession(user);
      _setState(AuthSignedIn(user));
    } on AuthFailure catch (failure, s) {
      if (!_isCurrentLoad(uid, generation)) return;
      // Show the error before reporting it: once reported, another session
      // may have started (PM-S3-5-03).
      _setState(AuthProfileError(uid, failure));
      await crashlytics.recordError(failure, s,
          reason: 'Profile load failed (${failure.kind.name})');
    } catch (e, s) {
      if (!_isCurrentLoad(uid, generation)) return;
      _setState(AuthProfileError(
          uid, AuthFailure(AuthFailureKind.unknown, cause: e)));
      await crashlytics.recordError(e, s, reason: 'Profile load failed');
    }
  }

  /// Sends an Analytics event. A failure is recorded, never thrown: the
  /// session state has already changed and must not depend on telemetry.
  Future<void> _sendTelemetry(Future<void> Function() send,
      {required String reason}) async {
    try {
      await send();
    } catch (e, s) {
      await crashlytics.recordError(e, s, reason: reason);
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
