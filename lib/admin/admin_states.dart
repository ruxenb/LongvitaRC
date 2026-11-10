import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'admin_viewmodels.dart';

class AdminStateView extends StatelessWidget {
  final AdminLoadState state;
  final String? error;
  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback? retry;

  const AdminStateView({
    super.key,
    required this.state,
    this.error,
    required this.emptyTitle,
    required this.emptyMessage,
    this.retry,
  });

  @override
  Widget build(BuildContext context) {
    if (state == AdminLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final failed = state == AdminLoadState.error;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                failed ? Icons.cloud_off_outlined : Icons.inbox_outlined,
                size: 52,
                color: failed
                    ? AppColors.feedbackError
                    : AppColors.actionPrimary,
              ),
              const SizedBox(height: 16),
              Text(
                failed ? 'Không tải được dữ liệu' : emptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                failed ? (error ?? 'Lỗi không xác định') : emptyMessage,
                textAlign: TextAlign.center,
              ),
              if (retry != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AdminPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      ?action,
    ],
  );
}
