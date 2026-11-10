import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:longvita_core/theme/app_colors.dart';
import 'package:longvita_core/theme/app_spacing.dart';
import 'package:longvita_core/theme/app_typography.dart';

/// `Longvita/TextField` (Figma 55:143): Default / Focused / Filled / Error /
/// Disabled.
///
/// Label (Label) above a 52+ high input (radius 8, padding 16) with an
/// optional trailing [unit]; [helperText] below in Supporting. When
/// [errorText] is non-null the border and message switch to feedback/error
/// and replace the helper. Validation itself belongs to the ViewModel.
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? unit;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.unit,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final message = hasError ? errorText : helperText;

    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.rounded8,
          borderSide: BorderSide(color: color, width: width),
        );

    final idleBorder = outline(
      hasError ? AppColors.feedbackError : AppColors.borderControl,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.disabledText,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Semantics(
          label: label,
          hint: message,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: AppTypography.body.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.disabledText,
            ),
            cursorColor: AppColors.actionPrimary,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: enabled ? AppColors.bgSurface : AppColors.disabledBg,
              hintText: hintText,
              hintStyle: AppTypography.body.copyWith(
                color: enabled
                    ? AppColors.textSecondary
                    : AppColors.disabledText,
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.s16),
              suffixIcon: unit == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.s8,
                        right: AppSpacing.s16,
                      ),
                      child: Text(
                        unit!,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
              suffixIconConstraints: const BoxConstraints(),
              border: idleBorder,
              enabledBorder: idleBorder,
              disabledBorder: outline(AppColors.borderControl),
              focusedBorder: hasError
                  ? outline(AppColors.feedbackError)
                  : outline(AppColors.borderFocus, 2),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.s8),
          ExcludeSemantics(
            child: Text(
              message,
              style: AppTypography.supporting.copyWith(
                color: hasError
                    ? AppColors.feedbackError
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
