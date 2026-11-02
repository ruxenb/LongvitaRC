import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_state.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/state_views.dart';
import '../theme/app_spacing.dart';
import 'auth_recovery_screen.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

/// Routes by [AuthState] (S3-6, owner Thắng; auth states from S3-3).
///
/// Only [AuthSignedIn] reaches protected content. When the session ends,
/// routes pushed above this gate are removed so Back cannot return to
/// protected screens of the previous user.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _wasSignedIn = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthViewModel>().state;

    final signedIn = state is AuthSignedIn;
    if (_wasSignedIn && !signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
    _wasSignedIn = signedIn;

    return switch (state) {
      AuthInitializing() => const _GateLoading(
          title: 'Đang kiểm tra phiên đăng nhập',
        ),
      AuthLoadingProfile() => const _GateLoading(
          title: 'Đang tải hồ sơ của bạn',
        ),
      AuthSignedOut() || AuthSigningIn() => const SignInScreen(),
      AuthProfileError(:final failure) => AuthRecoveryScreen(failure: failure),
      AuthSignedIn() => const HomeScreen(),
    };
  }
}

class _GateLoading extends StatelessWidget {
  final String title;
  const _GateLoading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pageMargin),
            child: LoadingView(title: title),
          ),
        ),
      ),
    );
  }
}
