import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon_button.dart';

/// `Longvita/CheckboxRow` (Figma 56:213): min height 48, padding 8, gap 8;
/// 48 hit area with a 24px square (border/control) when unchecked, the
/// action/primary check icon when checked, decorative border and
/// disabled text when [onChanged] is null.
class AppCheckboxRow extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  const AppCheckboxRow({
    super.key,
    required this.label,
    required this.checked,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    final Widget mark;
    if (checked) {
      // Figma has no Disabled+Checked variant; keep the check shape and use
      // disabled/text so the state is never shown by colour alone.
      mark = Icon(AppIcons.check,
          size: AppSizes.icon,
          color: enabled ? AppColors.actionPrimary : AppColors.disabledText);
    } else {
      mark = Container(
        width: AppSizes.icon,
        height: AppSizes.icon,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border.all(
            color:
                enabled ? AppColors.borderControl : AppColors.borderDecorative,
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      checked: checked,
      enabled: enabled,
      label: label,
      onTap: enabled ? () => onChanged!(!checked) : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onChanged!(!checked) : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.touchMin),
            padding: const EdgeInsets.all(AppSpacing.s8),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: AppSizes.touchMin,
                  child: Center(child: mark),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.disabledText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `Longvita/DaySelector` (Figma 56:198): 48 wide pill, min height 48,
/// padding 4; day (Label) over date (Label/Strong). Selected uses
/// action/primary with on-primary text, otherwise white with text/primary.
class AppDaySelector extends StatelessWidget {
  final String day;
  final String date;
  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AppDaySelector({
    super.key,
    required this.day,
    required this.date,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? AppColors.actionOnPrimary : AppColors.textPrimary;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: semanticLabel ?? '$day $date',
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: AppSizes.touchMin,
            constraints: const BoxConstraints(minHeight: AppSizes.touchMin),
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: BoxDecoration(
              color: selected ? AppColors.actionPrimary : AppColors.bgSurface,
              borderRadius: AppRadius.roundedFull,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(day,
                    style: AppTypography.label.copyWith(color: foreground)),
                Text(date,
                    style:
                        AppTypography.labelStrong.copyWith(color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `Longvita/QuantityStepper` (Figma 57:260): canvas pill, padding 4,
/// gap 8; minus/plus [AppIconButton]s (text/primary) around a centred
/// Label/Strong value. Bounds and validation stay in the ViewModel: pass a
/// null callback to disable a side.
class AppQuantityStepper extends StatelessWidget {
  final String valueLabel;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final String decrementSemanticLabel;
  final String incrementSemanticLabel;
  final double width;

  const AppQuantityStepper({
    super.key,
    required this.valueLabel,
    this.onDecrement,
    this.onIncrement,
    this.decrementSemanticLabel = 'Decrease',
    this.incrementSemanticLabel = 'Increase',
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: const BoxDecoration(
        color: AppColors.bgCanvas,
        borderRadius: AppRadius.roundedFull,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: AppIcons.remove,
            semanticLabel: decrementSemanticLabel,
            color: AppColors.textPrimary,
            onPressed: onDecrement,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                valueLabel,
                textAlign: TextAlign.center,
                style: AppTypography.labelStrong,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          AppIconButton(
            icon: AppIcons.add,
            semanticLabel: incrementSemanticLabel,
            color: AppColors.textPrimary,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

/// Visual body of `Longvita/Snackbar` (Figma 57:256): action/pressed fill,
/// radius 16, padding 16, Supporting message and a 64×48 Undo target in
/// Label/Strong. Use [showAppSnackBar] to display it.
class AppSnackBarContent extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppSnackBarContent({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.actionPressed,
        borderRadius: AppRadius.rounded16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTypography.supporting
                  .copyWith(color: AppColors.actionOnPrimary),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: AppSpacing.s8),
            Semantics(
              container: true,
              button: true,
              label: actionLabel,
              onTap: onAction,
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Container(
                    width: 64,
                    constraints:
                        const BoxConstraints(minHeight: AppSizes.touchMin),
                    padding: const EdgeInsets.all(AppSpacing.s8),
                    alignment: Alignment.center,
                    child: Text(
                      actionLabel!,
                      style: AppTypography.labelStrong
                          .copyWith(color: AppColors.actionOnPrimary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows [AppSnackBarContent] as a floating snackbar with a 16 margin
/// (328 wide on a 360 screen). The action hides the snackbar before calling
/// [onAction]; what Undo restores is decided by the caller's ViewModel.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  return messenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.all(AppSpacing.s16),
      content: AppSnackBarContent(
        message: message,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                messenger.hideCurrentSnackBar(
                    reason: SnackBarClosedReason.action);
                onAction();
              },
      ),
    ),
  );
}
