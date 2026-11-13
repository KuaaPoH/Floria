import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // He thong mau sac cao cap linh hon thien nhien
  static const Color primaryGreen = Color(0xFF0F9D58);
  static const Color primaryDarkGreen = Color(0xFF0B6638);
  static const Color accentGreen = Color(0xFFE8F5E9);
  
  // Dark mode tông xanh rêu đêm (đồng bộ với AppColors.dark)
  static const Color darkBackground = Color(0xFF0F1511);
  static const Color darkSurface = Color(0xFF19211B);
  static const Color darkCard = Color(0xFF19211B);

  static const Color lightBackground = Color(0xFFF5F7F5);
  static const Color lightSurface = Colors.white;

  // Theme Light Mode
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryDarkGreen,
        surface: lightSurface,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
    );
  }

  // Theme Dark Mode (Sleek Dark)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7FCB95),
        onPrimary: Color(0xFF0F1511),
        secondary: Color(0xFF3E8055),
        surface: darkSurface,
        onSurface: Color(0xFFE6ECE6),
      ),
      scaffoldBackgroundColor: darkBackground,
      dividerColor: const Color(0xFF2E3A31),
      dialogTheme: const DialogThemeData(backgroundColor: darkSurface),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: darkSurface),
      snackBarTheme: const SnackBarThemeData(contentTextStyle: TextStyle(color: Colors.white)),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
