import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central place for Scholivax's brand colors + typography so every screen
/// (old and new) pulls from the same palette instead of hardcoding hex
/// values inline.
class AppColors {
  static const navy = Color(0xFF1A2E45);
  static const navyDeep = Color(0xFF101D2C);
  static const gold = Color(0xFFE8A93B);
  static const surface = Color(0xFFF5F7FA);
  static const surfaceAlt = Color(0xFFEEF2FF);
  static const border = Color(0xFFE5E9F0);
  static const textMuted = Color(0xFF6B7280);

  // Accent palette used to color-code portal cards/categories so a busy
  // grid of buttons still feels organized at a glance.
  static const accents = <Color>[
    Color(0xFF3B82F6), // blue
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFFEC4899), // pink
    Color(0xFF6366F1), // indigo
  ];

  /// Each role gets its own dashboard header color, echoing the reference
  /// designs: Admin = indigo/violet, Teacher = blue, Student = green,
  /// Parent = teal.
  static List<Color> headerGradient(String userType) {
    switch (userType) {
      case 'admin':
        return const [Color(0xFF4F46E5), Color(0xFF7C3AED)];
      case 'teacher':
        return const [Color(0xFF2563EB), Color(0xFF1D4ED8)];
      case 'student':
        return const [Color(0xFF16A34A), Color(0xFF15803D)];
      case 'parent':
        return const [Color(0xFF0D9488), Color(0xFF0F766E)];
      default:
        return const [Color(0xFF1A2E45), Color(0xFF101D2C)];
    }
  }
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.navy,
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.poppins(),
        hintStyle: GoogleFonts.poppins(color: AppColors.textMuted),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
