import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:longvita_core/longvita_core.dart';

/// Presentation only: auth and role decisions belong to AdminAuthViewModel.
class SignInWebScreen extends StatelessWidget {
  final bool busy;
  final String? message;
  final VoidCallback onSignIn;
  const SignInWebScreen({
    super.key,
    required this.onSignIn,
    this.busy = false,
    this.message,
  });

  @override
  Widget build(BuildContext context) => AdminAuthCard(
    title: 'Trang quản trị Longvita',
    icon: Icons.eco_outlined,
    children: [
      const Text('Quản trị dinh dưỡng trường thọ', textAlign: TextAlign.center),
      if (message != null) ...[
        const SizedBox(height: AppSpacing.s24),
        Semantics(
          liveRegion: true,
          child: Text(
            message!,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.feedbackError),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.s24),
      AppButton(
        text: 'Đăng nhập bằng Google',
        icon: Icons.login,
        isLoading: busy,
        loadingText: 'Đang mở tài khoản Google…',
        onPressed: busy ? null : onSignIn,
      ),
      if (busy) ...[
        const SizedBox(height: AppSpacing.s16),
        const Text(
          'Hoàn tất hoặc đóng cửa sổ Google để tiếp tục.',
          textAlign: TextAlign.center,
        ),
      ],
    ],
  );
}

class AdminAuthCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const AdminAuthCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 48, color: AppColors.actionPrimary),
              const SizedBox(height: AppSpacing.s24),
              Semantics(
                header: true,
                headingLevel: 1,
                child: Text(
                  title,
                  style: AppTypography.headingM,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              ...children,
            ],
          ),
        ),
      ),
    );
    return VietnameseUi(
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - 32),
                  ),
                  child: Center(child: card),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AdminAuthMessage extends StatelessWidget {
  final String title;
  final String message;
  final String actionText;
  final VoidCallback action;
  final VoidCallback? changeAccount;
  const AdminAuthMessage({
    super.key,
    required this.title,
    required this.message,
    required this.actionText,
    required this.action,
    this.changeAccount,
  });

  @override
  Widget build(BuildContext context) => AdminAuthCard(
    title: title,
    icon: Icons.lock_outline,
    children: [
      Semantics(
        liveRegion: true,
        child: Text(message, textAlign: TextAlign.center),
      ),
      const SizedBox(height: AppSpacing.s24),
      AppButton(text: actionText, onPressed: action),
      if (changeAccount != null) ...[
        const SizedBox(height: AppSpacing.s12),
        AppButton(
          text: 'Đổi tài khoản',
          onPressed: changeAccount,
          variant: AppButtonVariant.secondary,
        ),
      ],
    ],
  );
}

class AdminAuthProgress extends StatelessWidget {
  final String label;
  final VoidCallback? changeAccount;
  const AdminAuthProgress({super.key, required this.label, this.changeAccount});

  @override
  Widget build(BuildContext context) => AdminAuthCard(
    title: label,
    icon: Icons.eco_outlined,
    children: [
      Center(child: CircularProgressIndicator(semanticsLabel: label)),
      if (changeAccount != null) ...[
        const SizedBox(height: AppSpacing.s24),
        AppButton(
          text: 'Đổi tài khoản',
          onPressed: changeAccount,
          variant: AppButtonVariant.secondary,
        ),
      ],
    ],
  );
}
