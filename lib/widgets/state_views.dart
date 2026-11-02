import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Shared container of the three `Longvita/State/*` components: white,
/// radius 16, padding 24, gap 16, centred content, full available width.
class _StatePanel extends StatelessWidget {
  final List<Widget> children;

  const _StatePanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.rounded16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s16),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// `Longvita/State/Loading` styles (Figma 57:181).
enum LoadingViewStyle { spinner, skeleton }

/// `Longvita/State/Loading` (Figma 57:181): Spinner (40px progress arc,
/// stroke 3, action/primary) or Skeleton (three bg/selected bones), then
/// Title and Supporting text centred. Announced as a live region.
class LoadingView extends StatelessWidget {
  final String? title;
  final String? message;
  final LoadingViewStyle style;

  const LoadingView({
    super.key,
    this.title,
    this.message,
    this.style = LoadingViewStyle.spinner,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: [title, message].whereType<String>().join('. '),
      child: ExcludeSemantics(
        child: _StatePanel(
          children: [
            if (style == LoadingViewStyle.spinner)
              const Center(child: AppSpinner())
            else
              const _SkeletonBones(),
            if (title != null)
              Text(title!,
                  textAlign: TextAlign.center, style: AppTypography.title),
            if (message != null)
              Text(message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.supporting),
          ],
        ),
      ),
    );
  }
}

/// The 40px spinner from Figma node 61:595: a 270° arc (stroke 3, round
/// caps, action/primary) whose gap sits in the top-right quadrant at rest.
class AppSpinner extends StatefulWidget {
  final double size;

  const AppSpinner({super.key, this.size = 40});

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: const _ArcPainter(),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..color = AppColors.actionPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // From 3 o'clock clockwise through 6 and 9 to 12 o'clock.
    canvas.drawArc(rect, 0, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => false;
}

class _SkeletonBones extends StatelessWidget {
  const _SkeletonBones();

  @override
  Widget build(BuildContext context) {
    Widget bone(double width, double height) => Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            color: AppColors.bgSelected,
            borderRadius: AppRadius.rounded16,
          ),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final max = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bone(math.min(280, max), 64),
            const SizedBox(height: AppSpacing.s12),
            bone(math.min(220, max), 16),
            const SizedBox(height: AppSpacing.s12),
            bone(math.min(160, max), 16),
          ],
        );
      },
    );
  }
}

/// `Longvita/State/Empty` (Figma 57:212): 64px bg/selected pill holding a
/// 24px action/primary icon, Heading/M title, Body message and one primary
/// CTA that continues the flow.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    this.icon = AppIcons.calendarToday,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      children: [
        Center(
          child: ExcludeSemantics(
            child: Container(
              width: 64,
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: const BoxDecoration(
                color: AppColors.bgSelected,
                borderRadius: AppRadius.roundedFull,
              ),
              child: Icon(icon,
                  size: AppSizes.icon, color: AppColors.actionPrimary),
            ),
          ),
        ),
        Semantics(
          header: true,
          child: Text(title,
              textAlign: TextAlign.center, style: AppTypography.headingM),
        ),
        if (message != null)
          Text(
            message!,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        if (actionLabel != null)
          AppButton(text: actionLabel!, onPressed: onAction),
      ],
    );
  }
}

/// `Longvita/State/Error` (Figma 57:255): error_outline icon in
/// feedback/error, Heading/M title, Body message that says what was kept,
/// primary "Try again" with refresh icon and secondary "Go back".
class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final String? backLabel;
  final VoidCallback? onBack;

  const ErrorView({
    super.key,
    required this.title,
    required this.message,
    this.retryLabel = 'Try again',
    this.onRetry,
    this.backLabel,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: _StatePanel(
        children: [
          const Center(
            child: ExcludeSemantics(
              child: Icon(AppIcons.errorOutline,
                  size: AppSizes.icon, color: AppColors.feedbackError),
            ),
          ),
          Semantics(
            header: true,
            child: Text(title,
                textAlign: TextAlign.center, style: AppTypography.headingM),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          if (onRetry != null)
            AppButton(
              text: retryLabel,
              icon: AppIcons.refresh,
              onPressed: onRetry,
            ),
          if (backLabel != null)
            AppButton(
              text: backLabel!,
              variant: AppButtonVariant.secondary,
              onPressed: onBack,
            ),
        ],
      ),
    );
  }
}
