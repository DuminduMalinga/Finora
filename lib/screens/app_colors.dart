import 'package:flutter/material.dart';

import 'finora_theme.dart';

/// Colours that follow the light/dark theme. Use these instead of fixed
/// colours for text, cards, borders and backgrounds.
extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Strong text and icons.
  Color get ink => isDark ? const Color(0xFFF1F5F9) : navy;

  /// Secondary text.
  Color get muted => isDark ? const Color(0xFF9AA8BD) : const Color(0xFF64748B);

  /// Hints, placeholders and disabled text.
  Color get faint => isDark ? const Color(0xFF7B8AA0) : const Color(0xFF94A3B8);

  /// Cards, sheets and inputs.
  Color get surface => isDark ? const Color(0xFF162033) : Colors.white;

  /// The page behind cards.
  Color get page => isDark ? const Color(0xFF0B1220) : canvas;

  /// Quiet fills: unselected tiles, tracks, input backgrounds.
  Color get subtle =>
      isDark ? const Color(0xFF1D2A42) : const Color(0xFFF5F7FA);

  /// Hairlines and outlines.
  Color get line => isDark ? const Color(0xFF2C3A56) : const Color(0xFFE2E8F0);

  /// Selected or highlighted backgrounds.
  Color get tint => isDark ? const Color(0xFF1F3354) : paleBlue;

  /// Filled buttons and selected chips (white text sits on top).
  Color get primary => isDark ? const Color(0xFF3B5BA9) : navy;
}
