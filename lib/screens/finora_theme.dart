import 'package:flutter/material.dart';

/// Finora's palette: a bright lime accent on near-black ink over a soft
/// green-tinted page. The old names are kept so every screen picks it up.
const navy = Color(0xFF111611); // ink / primary dark
const emerald = Color(0xFFC5F135); // lime accent
const paleBlue = Color(0xFFEAF9D3); // pale lime tint
const canvas = Color(0xFFEAF9D3); // page background
const coral = Color(0xFFE5484D);
const amber = Color(0xFFF5B301);

const limeDeep = Color(0xFFA8D81E);
const mutedInk = Color(0xFF4B5743);
const hairline = Color(0xFFE6EFD8);

const fontFamily = 'Outfit';

class FinoraTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: canvas,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: emerald,
          brightness: Brightness.light,
        ).copyWith(
          primary: navy,
          onPrimary: emerald,
          secondary: emerald,
          onSecondary: navy,
          surface: Colors.white,
          onSurface: navy,
          outline: hairline,
          outlineVariant: hairline,
        ),
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: navy,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        color: navy,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: hairline),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: emerald,
        minimumSize: const Size(88, 56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        shape: const StadiumBorder(),
        side: const BorderSide(color: navy, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: navy),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: navy,
      contentTextStyle: const TextStyle(
        fontFamily: fontFamily,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: emerald),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: navy,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        color: navy,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: navy,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(
        color: mutedInk,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
    ),
  );

  static ThemeData darkTheme(Color accent) {
    const surface = Color(0xFF161C16);
    const page = Color(0xFF0C110C);
    const text = Color(0xFFF1F6E8);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: page,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: emerald,
            brightness: Brightness.dark,
          ).copyWith(
            primary: emerald,
            onPrimary: navy,
            secondary: accent,
            onSecondary: navy,
            surface: surface,
            onSurface: text,
            onSurfaceVariant: const Color(0xFFA9B59B),
            outline: const Color(0xFF2A322A),
            outlineVariant: const Color(0xFF2A322A),
            surfaceContainer: const Color(0xFF1E261E),
            surfaceContainerLow: const Color(0xFF1E261E),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: page,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A322A)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: navy,
          minimumSize: const Size(88, 56),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: text),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: emerald,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: navy,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
