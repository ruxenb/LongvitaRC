// QA host for S4-14: the real SignInScreen and AuthViewModel over the fake
// auth service, for walking Sign-in with TalkBack on a device without
// signing out of the installed app. No Firebase or Google sign-in runs here.
//
//   flutter build apk --debug -t test/qa/sign_in_talkback_host.dart
//
// Installing it over the app keeps the app's data (and its session); put the
// normal build back afterwards.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/screens/sign_in_screen.dart';
import 'package:longvita/theme/app_theme.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

import '../auth/auth_fakes.dart';

/// The picker stays open long enough to hear the loading state, then the
/// attempts end as: cancelled, network failure, cancelled, and so on.
class _ScriptedAuth extends FakeAuthService {
  static const _results = <AuthSignInResult>[
    AuthSignInCancelled(),
    AuthSignInFailed(AuthFailure(AuthFailureKind.network)),
  ];

  @override
  Future<AuthSignInResult> signInWithGoogle() {
    pendingSignIn = Completer();
    final result = _results[signInCalls % _results.length];
    Timer(const Duration(seconds: 3), () => pendingSignIn!.complete(result));
    return super.signInWithGoogle();
  }
}

void main() {
  final auth = AuthViewModel(
    authService: _ScriptedAuth(),
    analytics: FakeAnalytics(),
    crashlytics: FakeCrashlytics(),
  );
  runApp(
    ChangeNotifierProvider<AuthViewModel>.value(
      value: auth,
      child: MaterialApp(
        title: 'Longvita QA: Sign-in',
        theme: AppTheme.lightTheme,
        home: const SignInScreen(),
      ),
    ),
  );
}
