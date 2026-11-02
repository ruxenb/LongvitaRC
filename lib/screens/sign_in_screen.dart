import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_state.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/longvita_widgets.dart';
import 'auth_messages.dart';

/// Sign-in (S3-4). No approved Figma frame exists (S1-5), so the layout is
/// composed from the Longvita design system: brand, Heading/L, Body, an
/// outcome notice and one primary Google action. All logic lives in
/// [AuthViewModel].
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final state = vm.state;
    final signingIn = state is AuthSigningIn;
    final notice = state is AuthSignedOut ? state.notice : null;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageMargin),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSpacing.pageMargin * 2,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Longvita',
                        style: AppTypography.brand
                            .copyWith(color: AppColors.actionPrimary),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ExcludeSemantics(
                        child: Container(
                          width: 64,
                          padding: const EdgeInsets.all(AppSpacing.s16),
                          decoration: const BoxDecoration(
                            color: AppColors.bgSelected,
                            borderRadius: AppRadius.roundedFull,
                          ),
                          child: const Icon(AppIcons.spa,
                              size: AppSizes.icon,
                              color: AppColors.actionPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    const Text(
                      'Thực đơn trường thọ cho cả tuần',
                      style: AppTypography.headingL,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      'Đăng nhập để lưu thực đơn, danh sách đi chợ '
                      'và báo cáo của bạn trên mọi lần mở ứng dụng.',
                      style: AppTypography.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpacing.s24),
                    if (notice != null) ...[
                      _SignInNotice(
                        failure: notice,
                        onDismiss: vm.clearNotice,
                      ),
                      const SizedBox(height: AppSpacing.s16),
                    ],
                    AppButton(
                      key: const Key('sign-in-google'),
                      text: notice == null ||
                              notice.kind == AuthFailureKind.cancelled
                          ? 'Đăng nhập bằng Google'
                          : 'Thử lại với Google',
                      loadingText: 'Đang mở tài khoản Google…',
                      icon: AppIcons.arrowForward,
                      isLoading: signingIn,
                      onPressed: vm.isBusy ? null : vm.signInWithGoogle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outcome of the last attempt. A cancel is informational (no error
/// colour); failures use feedback/error with an icon and text, never colour
/// alone.
class _SignInNotice extends StatelessWidget {
  final AuthFailure failure;
  final VoidCallback onDismiss;

  const _SignInNotice({required this.failure, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isCancel = failure.kind == AuthFailureKind.cancelled;
    final message = AuthMessages.signInNotice(failure);

    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16, AppSpacing.s12, AppSpacing.s4, AppSpacing.s12),
        decoration: BoxDecoration(
          color: isCancel ? AppColors.bgSelected : AppColors.bgSurface,
          borderRadius: AppRadius.rounded12,
        ),
        foregroundDecoration: isCancel
            ? null
            : BoxDecoration(
                border: Border.all(color: AppColors.feedbackError),
                borderRadius: AppRadius.rounded12,
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s12),
              child: ExcludeSemantics(
                child: Icon(
                  isCancel ? AppIcons.infoOutline : AppIcons.errorOutline,
                  size: AppSizes.icon,
                  color: isCancel
                      ? AppColors.actionPrimary
                      : AppColors.feedbackError,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                child: ExcludeSemantics(
                  child: Text(
                    message,
                    style: AppTypography.supporting.copyWith(
                      color: isCancel
                          ? AppColors.textPrimary
                          : AppColors.feedbackError,
                    ),
                  ),
                ),
              ),
            ),
            AppIconButton(
              icon: AppIcons.close,
              semanticLabel: 'Ẩn thông báo',
              color: AppColors.textSecondary,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
