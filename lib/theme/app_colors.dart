import 'package:flutter/material.dart';

/// Longvita colour tokens, mirrored from Figma "Longvita / Foundations v1"
/// (node 53:2) and the variables bound in Page 05 Components.
///
/// Use the Figma-named tokens below. The "Legacy aliases" section only keeps
/// older skeleton code compiling; each alias points at an approved token.
class AppColors {
  AppColors._();

  // Action
  /// `color/action/primary` — primary buttons, selected nav, brand title.
  static const Color actionPrimary = Color(0xFF476429);

  /// `color/action/pressed` — pressed primary button, Undo snackbar.
  static const Color actionPressed = Color(0xFF324E15);

  /// `color/action/on-primary` — text/icons on [actionPrimary].
  static const Color actionOnPrimary = Color(0xFFFFFFFF);

  // Background
  /// `color/bg/canvas` — page background, app bar, navigation bar.
  static const Color bgCanvas = Color(0xFFF6F1E7);

  /// `color/bg/surface` — cards, dialogs, inputs.
  static const Color bgSurface = Color(0xFFFFFFFF);

  /// `color/bg/selected` — selected/soft fills, badges, skeleton bones.
  static const Color bgSelected = Color(0xFFE4F2DA);

  /// `color/bg/pressed` — pressed card.
  static const Color bgPressed = Color(0xFFEEE6D6);

  /// `color/bg/soft` — App Suggestion badge.
  static const Color bgSoft = Color(0xFFEAF8DF);

  // Text
  /// `color/text/primary` — 10.48:1 on canvas.
  static const Color textPrimary = Color(0xFF2F3B2A);

  /// `color/text/secondary` — 5.06:1 on canvas.
  static const Color textSecondary = Color(0xFF5C6B53);

  // Border
  /// `color/border/control` — input and checkbox outlines (3.97:1).
  static const Color borderControl = Color(0xFF74796C);

  /// `color/border/focus` — focused input (2px).
  static const Color borderFocus = Color(0xFF476429);

  /// `color/border/decorative` — decoration only, never the sole control cue.
  static const Color borderDecorative = Color(0xFFDCCDB0);

  // Feedback
  /// `color/feedback/error` — always paired with a text message.
  static const Color feedbackError = Color(0xFFBA1A1A);

  // Disabled
  /// `disabled/bg`
  static const Color disabledBg = Color(0xFFE4E2DB);

  /// `disabled/text`
  static const Color disabledText = Color(0xFF62685D);

  // Legacy aliases (skeleton code before CHARLIE-UI-01).
  static const Color primary = actionPrimary;
  static const Color onPrimary = actionOnPrimary;
  static const Color primaryContainer = bgSelected;
  static const Color onPrimaryContainer = textPrimary;
  static const Color secondary = textSecondary;
  static const Color onSecondary = actionOnPrimary;
  static const Color secondaryContainer = bgSelected;
  static const Color onSecondaryContainer = textPrimary;
  static const Color outline = borderControl;
  static const Color outlineVariant = borderDecorative;
  static const Color surface = bgCanvas;
  static const Color onSurface = textPrimary;
  static const Color error = feedbackError;
  static const Color onError = actionOnPrimary;

  /// No success colour exists in Figma; positive confirmations use the
  /// snackbar fill.
  static const Color success = actionPressed;
}
