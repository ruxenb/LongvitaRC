import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/view_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_button.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final isLoading = authViewModel.state is ViewStateLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Brand / Logo
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Longvita',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Dinh Dưỡng Trường Thọ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.secondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ứng dụng phương pháp dinh dưỡng trường thọ của TS. Valter Longo thành thực đơn 7 ngày khoa học.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Error feedback if any
              if (authViewModel.state is ViewStateError) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: AppRadius.rounded12,
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    (authViewModel.state as ViewStateError).message,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              // Google Sign-In Button
              AppButton(
                text: 'Đăng nhập với Google',
                icon: Icons.login_rounded,
                isLoading: isLoading,
                onPressed: () async {
                  await authViewModel.signInWithGoogle();
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
