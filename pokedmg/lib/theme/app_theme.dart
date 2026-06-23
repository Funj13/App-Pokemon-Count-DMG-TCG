// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette - dark arena feel with red accent
  static const Color background    = Color(0xFF0D0D0D);
  static const Color surface       = Color(0xFF1A1A2E);
  static const Color surfaceCard   = Color(0xFF16213E);
  static const Color accent        = Color(0xFFE63946);
  static const Color accentGlow    = Color(0x33E63946);
  static const Color hpGreen       = Color(0xFF4CAF50);
  static const Color hpYellow      = Color(0xFFFFB300);
  static const Color hpRed         = Color(0xFFE63946);
  static const Color textPrimary   = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color divider       = Color(0xFF2A2A3E);

  static Color hpColor(double percent) {
    if (percent > 0.5) return hpGreen;
    if (percent > 0.25) return hpYellow;
    return hpRed;
  }

  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: surface,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.exo2TextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        titleLarge:   TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium:  TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge:    TextStyle(color: textPrimary),
        bodyMedium:   TextStyle(color: textSecondary),
        labelSmall:   TextStyle(color: textSecondary, letterSpacing: 1.2),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.exo2(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.exo2(fontWeight: FontWeight.w600, letterSpacing: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondary),
    ),
  );
}
