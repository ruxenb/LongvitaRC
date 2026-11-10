import 'package:flutter/material.dart';

import 'package:longvita_core/theme/app_colors.dart';
import 'package:longvita_core/theme/app_icons.dart';
import 'package:longvita_core/theme/app_spacing.dart';
import 'package:longvita_core/theme/app_typography.dart';
import 'package:longvita_core/widgets/app_button.dart';

/// `Longvita/Dialog` (Figma 57:169): white, radius 16, padding 24, gap 16,
/// Elevation/2; 24px icon, Heading/M title, Body message (text/secondary),
/// optional [content] (e.g. an [AppTextField]) and stacked full-width
/// actions without icons.
///
/// Kinds map to the named constructors: [AppDialog.confirmation],
/// [AppDialog.destructive], [AppDialog.error] and [AppDialog.edit]. For
/// EditError pass an `AppTextField` with `errorText` and a null
/// [onPrimary]: the primary button renders Disabled and the dialog stays
/// open, so the user can fix the value or cancel without data changing.
///
/// Like Material's `AlertDialog`, the dialog names its route with [title], so
/// TalkBack announces it when it opens. Pass [barrierLabel] to `showDialog`:
/// on Android the barrier is a focusable "dismiss" control, and the app has
/// no Vietnamese Material localizations, so its default label is English.
class AppDialog extends StatelessWidget {
  /// Spoken label of the area around the dialog, which closes it.
  static const barrierLabel = 'Đóng';

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? content;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final AppButtonVariant primaryVariant;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const AppDialog({
    super.key,
    required this.icon,
    this.iconColor = AppColors.actionPrimary,
    required this.title,
    this.message,
    this.content,
    required this.primaryLabel,
    this.onPrimary,
    this.primaryVariant = AppButtonVariant.primary,
    this.secondaryLabel,
    this.onSecondary,
  });

  /// Kind=Confirmation (bookmark icon, primary + secondary).
  const AppDialog.confirmation({
    super.key,
    this.icon = AppIcons.bookmarkBorder,
    required this.title,
    this.message,
    required this.primaryLabel,
    this.onPrimary,
    required this.secondaryLabel,
    this.onSecondary,
  }) : iconColor = AppColors.actionPrimary,
       content = null,
       primaryVariant = AppButtonVariant.primary;

  /// Kind=Destructive (delete icon in feedback/error, destructive button).
  const AppDialog.destructive({
    super.key,
    this.icon = AppIcons.deleteOutline,
    required this.title,
    this.message,
    required this.primaryLabel,
    this.onPrimary,
    required this.secondaryLabel,
    this.onSecondary,
  }) : iconColor = AppColors.feedbackError,
       content = null,
       primaryVariant = AppButtonVariant.destructive;

  /// Kind=Error (error icon in feedback/error, retry + cancel).
  const AppDialog.error({
    super.key,
    this.icon = AppIcons.errorOutline,
    required this.title,
    this.message,
    required this.primaryLabel,
    this.onPrimary,
    required this.secondaryLabel,
    this.onSecondary,
  }) : iconColor = AppColors.feedbackError,
       content = null,
       primaryVariant = AppButtonVariant.primary;

  /// Kind=Edit / EditError (edit icon + input content).
  const AppDialog.edit({
    super.key,
    this.icon = AppIcons.edit,
    required this.title,
    this.message,
    required Widget this.content,
    required this.primaryLabel,
    this.onPrimary,
    required this.secondaryLabel,
    this.onSecondary,
  }) : iconColor = AppColors.actionPrimary,
       primaryVariant = AppButtonVariant.primary;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Align(
        alignment: Alignment.centerLeft,
        child: ExcludeSemantics(
          child: Icon(icon, size: AppSizes.icon, color: iconColor),
        ),
      ),
      Semantics(
        header: true,
        headingLevel: 1,
        child: Text(title, style: AppTypography.headingM),
      ),
      if (message != null)
        Text(
          message!,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ?content,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            text: primaryLabel,
            onPressed: onPrimary,
            variant: primaryVariant,
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: AppSpacing.s8),
            AppButton(
              text: secondaryLabel!,
              onPressed: onSecondary,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ],
      ),
    ];

    final dialog = Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s24),
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadius.rounded16,
          boxShadow: AppElevation.level2,
        ),
        child: SingleChildScrollView(
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
        ),
      ),
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: dialog,
    );
  }
}
