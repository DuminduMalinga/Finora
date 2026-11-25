import 'package:flutter/material.dart';

import 'finora_theme.dart';

/// Colours that follow the light/dark theme. Use these instead of fixed
/// colours for text, cards, borders and backgrounds.
extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Strong text and icons.
  Color get ink => isDark ? const Color(0xFFF1F6E8) : navy;

  /// Secondary text.
  Color get muted => isDark ? const Color(0xFFA9B59B) : mutedInk;

  /// Hints, placeholders and disabled text.
  Color get faint => isDark ? const Color(0xFF8E9B80) : const Color(0xFF5E6B52);

  /// Cards, sheets and inputs.
  Color get surface => isDark ? const Color(0xFF161C16) : Colors.white;

  /// The page behind cards.
  Color get page => isDark ? const Color(0xFF0C110C) : canvas;

  /// Quiet fills: unselected tiles, tracks, input backgrounds.
  Color get subtle =>
      isDark ? const Color(0xFF1E261E) : const Color(0xFFF1F8E4);

  /// Hairlines and outlines.
  Color get line => isDark ? const Color(0xFF2A322A) : hairline;

  /// Selected or highlighted backgrounds.
  Color get tint => isDark ? const Color(0xFF26331A) : const Color(0xFFDDF59A);

  /// Filled buttons and selected chips: dark in light mode, lime in dark.
  Color get primary => isDark ? emerald : navy;

  /// Text and icons that sit on top of [primary].
  Color get onPrimary => isDark ? navy : emerald;

  /// Hero cards (balance, budget): near-black in both themes.
  Color get hero => isDark ? const Color(0xFF1E261E) : navy;
}
