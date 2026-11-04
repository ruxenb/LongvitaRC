import 'package:flutter/material.dart';

import '../models/view_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/state_views.dart';

/// Consistent narrow/mobile-first layout for all S02–S10 screens.
class FlowFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  const FlowFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pageMargin),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class FlowSection extends StatelessWidget {
  final String title;
  final Widget child;
  const FlowSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      const SizedBox(height: AppSpacing.s12),
      child,
      const SizedBox(height: AppSpacing.s16),
    ],
  );
}

class FlowItemCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const FlowItemCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.restaurant_menu_outlined,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Semantics(
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      label: title + (subtitle == null ? '' : '. ${subtitle!}'),
      child: ListTile(
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s4,
        ),
        minTileHeight: 56,
        leading: Icon(icon, size: 24, color: AppColors.actionPrimary),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: subtitle == null ? null : Text(subtitle!),
        onTap: onTap,
        trailing:
            trailing ??
            (onTap == null ? null : const Icon(Icons.chevron_right, size: 24)),
      ),
    ),
  );
}

/// Reusable explicit loading/empty/error display. No infinite spinner.
class FlowStateView<T> extends StatelessWidget {
  final ViewState<T> state;
  final Widget Function(T) onData;
  final VoidCallback onRetry;
  final VoidCallback? onBack;
  final String emptyTitle;

  const FlowStateView({
    super.key,
    required this.state,
    required this.onData,
    required this.onRetry,
    this.onBack,
    this.emptyTitle = 'Chưa có dữ liệu',
  });

  @override
  Widget build(BuildContext context) {
    final current = state;
    if (current is ViewStateLoading<T>) {
      return LoadingView(
        title: 'Đang tải',
        message: current.message ?? 'Vui lòng chờ dữ liệu...',
      );
    }
    if (current is ViewStateEmpty<T>) {
      return EmptyView(
        title: emptyTitle,
        message: current.message,
        actionLabel: 'Thử lại',
        onAction: onRetry,
      );
    }
    if (current is ViewStateError<T>) {
      return ErrorView(
        title: 'Không thể hoàn thành',
        message: current.message,
        retryLabel: 'Thử lại',
        onRetry: onRetry,
        backLabel: onBack == null ? null : 'Quay lại',
        onBack: onBack,
      );
    }
    if (current is ViewStateSuccess<T>) return onData(current.data);
    return EmptyView(
      title: emptyTitle,
      message: 'Chưa có thông tin để hiển thị.',
      actionLabel: 'Tải dữ liệu',
      onAction: onRetry,
    );
  }
}

void flowSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: actionLabel == null || onAction == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction),
    ),
  );
}
