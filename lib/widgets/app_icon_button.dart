import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// `Longvita/IconButton` (Figma 55:59): 48×48 pill target around a 24px
/// icon. Default / Pressed (bg/selected) / Disabled (null [onPressed]).
///
/// [semanticLabel] is required because the control has no visible text.
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Icon colour in Default/Pressed. Figma uses action/primary for
  /// navigation icons and text/primary for neutral actions.
  final Color color;

  /// Renders the Pressed variant without a pointer; for QA hosts only.
  @visibleForTesting
  final bool debugForcePressed;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.color = AppColors.actionPrimary,
    this.debugForcePressed = false,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final pressed = enabled && (_pressed || widget.debugForcePressed);

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: Container(
            width: AppSizes.touchMin,
            height: AppSizes.touchMin,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pressed ? AppColors.bgSelected : Colors.transparent,
              borderRadius: AppRadius.roundedFull,
            ),
            child: Icon(
              widget.icon,
              size: AppSizes.icon,
              color: enabled ? widget.color : AppColors.disabledText,
            ),
          ),
        ),
      ),
    );
  }
}
