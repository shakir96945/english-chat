import 'package:flutter/material';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand luxurious colors matching the premium black and gold theme
  static const Color goldPrimary = Color(0xFFD4AF37); // Metallic Gold
  static const Color goldLight = Color(0xFFF3E5AB);   // Soft Gold Accent
  static const Color goldDark = Color(0xFFAA7C11);    // Antique Gold
  static const Color charcoalDark = Color(0xFF0D0D0D); // Main Premium Black
  static const Color charcoalLight = Color(0xFF1A1A1A); // Dark Card Grey
  static const Color accentRose = Color(0xFFFF4081);   // Rose accent
  static const Color statusGreen = Color(0xFF4CAF50);  // Online indicator

  static const Gradient goldenGradient = LinearGradient(
    colors: [goldDark, goldPrimary, goldLight, goldPrimary, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: goldPrimary,
      scaffoldBackgroundColor: charcoalDark,
      cardColor: charcoalLight,
      colorScheme: const ColorScheme.dark(
        primary: goldPrimary,
        secondary: goldDark,
        background: charcoalDark,
        surface: charcoalLight,
        onPrimary: charcoalDark,
        onSecondary: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: goldPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.white70,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: charcoalDark,
        elevation: 0,
        iconTheme: IconThemeData(color: goldPrimary),
        centerTitle: true,
      ),
    );
  }
}
