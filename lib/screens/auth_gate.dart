import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/view_state.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/state_views.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final state = authViewModel.state;

    return switch (state) {
      ViewStateLoading() => const Scaffold(
          body: LoadingView(message: 'Đang kiểm tra thông tin đăng nhập...'),
        ),
      ViewStateSuccess() => const HomeScreen(),
      _ => const SignInScreen(),
    };
  }
}
