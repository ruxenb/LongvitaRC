import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outlined }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isLoading) {
      child = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(text),
        ],
      );
    } else {
      child = Text(text);
    }

    final buttonStyle = switch (variant) {
      AppButtonVariant.primary => ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
        ),
      AppButtonVariant.secondary => ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryContainer,
          foregroundColor: AppColors.onSecondaryContainer,
        ),
      AppButtonVariant.outlined => OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
        ),
    };

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: text,
      child: SizedBox(
        width: width,
        height: AppSpacing.minTouchTarget,
        child: variant == AppButtonVariant.outlined
            ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: buttonStyle,
                child: child,
              )
            : ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: buttonStyle,
                child: child,
              ),
      ),
    );
  }
}
