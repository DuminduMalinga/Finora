import 'package:flutter/material.dart';

const navy = Color(0xFF14213D);
const emerald = Color(0xFF10B981);
const paleBlue = Color(0xFFE8F3FF);
const canvas = Color(0xFFF8FAFC);
const coral = Color(0xFFEF4444);
const amber = Color(0xFFF59E0B);

class FinoraTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: emerald,
      surface: Colors.white,
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: navy,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        color: navy,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: navy,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF64748B),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
