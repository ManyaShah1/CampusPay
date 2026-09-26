import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// CampusPay Design System theme
/// Typography: Bodoni Moda (headlines/balances) + Plus Jakarta Sans (body/UI) + JetBrainsMono (tech labels)
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundWhite,
      primaryColor: AppColors.electricYellow,
      colorScheme: const ColorScheme.light(
        primary: AppColors.onSurface,
        primaryContainer: AppColors.electricYellow,
        secondary: AppColors.deepPurpleAlt,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.surfaceContainerLowest,
        error: AppColors.redAccent,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.onSurface,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: TextTheme(
        // Bodoni Moda — balance displays, editorial hero text
        displayLarge: GoogleFonts.bodoniModa(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
          letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.bodoniModa(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.bodoniModa(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          letterSpacing: -0.3,
        ),

        // Plus Jakarta Sans — titles and structural UI
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: 0.02,
        ),

        // Plus Jakarta Sans — body copy
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedText,
        ),

        // JetBrainsMono — technical labels, crypto IDs, nonces
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.deepPurpleAlt,
          letterSpacing: 0.08,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.deepPurpleAlt,
          letterSpacing: 0.04,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedText,
          letterSpacing: 0.04,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
          letterSpacing: 0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderStroke, width: 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricYellow,
          foregroundColor: AppColors.onElectricYellow,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.borderStroke, width: 1.5),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderStroke, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderStroke, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.deepPurpleAlt, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.mutedText),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        side: const BorderSide(color: AppColors.borderStroke, width: 1),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.onSurface,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderStroke),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedItemColor: AppColors.deepPurpleAlt,
        unselectedItemColor: AppColors.mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Alias darkTheme to lightTheme for consistent Neon White experience
  static ThemeData get darkTheme => lightTheme;
}
