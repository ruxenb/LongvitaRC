import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// `Longvita/Button` emphasis (Figma 55:111).
///
/// [outlined] predates the Figma library and renders exactly like
/// [secondary], which is the outlined Figma variant.
enum AppButtonVariant { primary, secondary, destructive, outlined }

/// `Longvita/Button` (Figma 55:111): Primary / Secondary / Destructive ×
/// Default / Pressed / Disabled / Loading.
///
/// - Disabled when [onPressed] is null.
/// - Loading shows the rotating `refresh` icon before [loadingText] (Figma
///   "Please wait…") and ignores taps.
/// - [icon] is the trailing 24px icon; pass null for a label-only button
///   (dialog and empty-state buttons in Figma have no icon).
/// - Min height 52, padding 16, radius 12, gap 8, Label/Strong centred.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingText;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;

  /// Renders the Pressed variant without a pointer; for QA hosts only.
  @visibleForTesting
  final bool debugForcePressed;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.loadingText,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width,
    this.debugForcePressed = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _syncSpin();
  }

  @override
  void didUpdateWidget(AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  void _syncSpin() {
    if (widget.isLoading && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.isLoading && _spin.isAnimating) {
      _spin
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  bool get _isSecondary =>
      widget.variant == AppButtonVariant.secondary ||
      widget.variant == AppButtonVariant.outlined;

  @override
  Widget build(BuildContext context) {
    final pressed = (_pressed || widget.debugForcePressed) && _enabled;
    final disabled = widget.onPressed == null && !widget.isLoading;

    final Color background;
    final Color foreground;
    BoxBorder? border;
    if (disabled) {
      background = AppColors.disabledBg;
      foreground = AppColors.disabledText;
    } else if (_isSecondary) {
      background = pressed ? AppColors.bgSelected : AppColors.bgSurface;
      foreground = AppColors.actionPrimary;
      border = Border.all(color: AppColors.actionPrimary);
    } else if (widget.variant == AppButtonVariant.destructive) {
      background = AppColors.feedbackError;
      foreground = AppColors.actionOnPrimary;
    } else {
      background = pressed ? AppColors.actionPressed : AppColors.actionPrimary;
      foreground = AppColors.actionOnPrimary;
    }

    final label = widget.isLoading
        ? (widget.loadingText ?? widget.text)
        : widget.text;

    final children = <Widget>[
      if (widget.isLoading)
        RotationTransition(
          turns: _spin,
          child: Icon(AppIcons.refresh, size: AppSizes.icon, color: foreground),
        ),
      Expanded(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelStrong.copyWith(color: foreground),
        ),
      ),
      if (!widget.isLoading && widget.icon != null)
        Icon(widget.icon, size: AppSizes.icon, color: foreground),
    ];

    return Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      label: label,
      onTap: _enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              _enabled ? () => setState(() => _pressed = false) : null,
          onTap: _enabled ? widget.onPressed : null,
          child: Container(
            width: widget.width ?? double.infinity,
            constraints:
                const BoxConstraints(minHeight: AppSizes.buttonMinHeight),
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.rounded12,
            ),
            // Figma strokes sit inside the frame, so the border must not
            // add to the 16 padding (a Container `decoration` border would).
            foregroundDecoration: border == null
                ? null
                : BoxDecoration(
                    border: border,
                    borderRadius: AppRadius.rounded12,
                  ),
            child: Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.s8),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
