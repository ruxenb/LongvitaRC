import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Light theme built from the Longvita Figma tokens (no dark mode exists in
/// Figma). Longvita widgets in `lib/widgets/` read tokens directly; these
/// component themes keep stock Material widgets close to the same tokens.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.actionPrimary,
      onPrimary: AppColors.actionOnPrimary,
      primaryContainer: AppColors.bgSelected,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.textSecondary,
      onSecondary: AppColors.actionOnPrimary,
      secondaryContainer: AppColors.bgSelected,
      onSecondaryContainer: AppColors.textPrimary,
      error: AppColors.feedbackError,
      onError: AppColors.actionOnPrimary,
      surface: AppColors.bgSurface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.disabledBg,
      outline: AppColors.borderControl,
      outlineVariant: AppColors.borderDecorative,
      shadow: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgCanvas,
      canvasColor: AppColors.bgCanvas,
      fontFamily: AppTypography.quicksand,
      textTheme: AppTypography.textTheme,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSizes.icon,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgCanvas,
        foregroundColor: AppColors.actionPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: AppSizes.appBarHeight,
        titleTextStyle:
            AppTypography.brand.copyWith(color: AppColors.actionPrimary),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rounded12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionPrimary,
          foregroundColor: AppColors.actionOnPrimary,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledText,
          minimumSize: const Size.fromHeight(AppSizes.buttonMinHeight),
          padding: const EdgeInsets.all(AppSpacing.s16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rounded12),
          elevation: 0,
          textStyle: AppTypography.labelStrong,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.bgSurface,
          foregroundColor: AppColors.actionPrimary,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledText,
          side: const BorderSide(color: AppColors.actionPrimary),
          minimumSize: const Size.fromHeight(AppSizes.buttonMinHeight),
          padding: const EdgeInsets.all(AppSpacing.s16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rounded12),
          textStyle: AppTypography.labelStrong,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.actionPrimary,
          minimumSize: const Size(AppSizes.touchMin, AppSizes.touchMin),
          textStyle: AppTypography.labelStrong,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        contentPadding: EdgeInsets.all(AppSpacing.s16),
        hintStyle: TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: AppRadius.rounded8,
          borderSide: BorderSide(color: AppColors.borderControl),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rounded8,
          borderSide: BorderSide(color: AppColors.borderControl),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rounded8,
          borderSide: BorderSide(color: AppColors.borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rounded8,
          borderSide: BorderSide(color: AppColors.feedbackError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rounded8,
          borderSide: BorderSide(color: AppColors.feedbackError),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rounded8,
          borderSide: BorderSide(color: AppColors.borderControl),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rounded16),
        insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.actionPressed,
        contentTextStyle:
            AppTypography.supporting.copyWith(color: AppColors.actionOnPrimary),
        actionTextColor: AppColors.actionOnPrimary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rounded16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.actionPrimary,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderDecorative),
    );
  }
}
