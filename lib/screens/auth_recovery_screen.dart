import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_state.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/longvita_widgets.dart';
import 'auth_messages.dart';

/// Shown when Firebase has a signed-in user but `users/{uid}` could not be
/// read or created. Protected screens stay closed; the user can retry the
/// profile or sign out, so the app is never stuck on Sign-in for no reason.
class AuthRecoveryScreen extends StatelessWidget {
  final AuthFailure failure;

  const AuthRecoveryScreen({super.key, required this.failure});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AuthViewModel>();
    return Scaffold(
      appBar: const AppTopBar(),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageMargin),
            child: ErrorView(
              title: AuthMessages.profileErrorTitle(failure),
              message: AuthMessages.profileErrorMessage(failure),
              retryLabel: 'Thử lại',
              onRetry: vm.retryProfile,
              backLabel: 'Đăng xuất',
              onBack: vm.signOut,
            ),
          ),
        ),
      ),
    );
  }
}
