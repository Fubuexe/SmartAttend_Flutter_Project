import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for SmartAttend.
/// Light, modern, indigo/violet brand — matches the Figma screens.
class AppColors {
  static const Color primary = Color(0xFF6C5CE7); // brand violet
  static const Color primaryDark = Color(0xFF5246C9);
  static const Color primaryLight = Color(0xFFEDEBFB);
  static const Color accent = Color(0xFF00B894);
  static const Color warning = Color(0xFFF6B93B);
  static const Color danger = Color(0xFFE74C3C);

  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1E2235);
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color border = Color(0xFFE5E7EF);

  static const Color focused = Color(0xFF00B894);   // green
  static const Color distracted = Color(0xFFF6B93B); // amber
  static const Color absent = Color(0xFFE74C3C);     // red
}

class AppTheme {
  // Backward-compatible naming used by app.dart
  static ThemeData get lightTheme => light;

  // Used by some screens (typo/alias)
  static Color get primaryColor => AppColors.primary;

  // Original theme entrypoint
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        background: AppColors.bg,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
