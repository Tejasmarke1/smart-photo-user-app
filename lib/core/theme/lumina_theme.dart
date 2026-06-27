import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class LuminaTheme {
  LuminaTheme._();

  /// Returns dark theme configuration (Obsidian System)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LuminaTokens.darkBg,
      primaryColor: LuminaTokens.primary,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: LuminaTokens.primary,
        onPrimary: Colors.white,
        secondary: LuminaTokens.secondary,
        onSecondary: Colors.white,
        error: LuminaTokens.error,
        onError: Colors.white,
        surface: LuminaTokens.darkSurface,
        onSurface: LuminaTokens.darkText,
        outline: LuminaTokens.darkBorder,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: LuminaTokens.textDisplay,
          fontWeight: LuminaTokens.fontWeightBold,
          color: LuminaTokens.darkText,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: LuminaTokens.textXxxl,
          fontWeight: LuminaTokens.fontWeightBold,
          color: LuminaTokens.darkText,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: LuminaTokens.textXl,
          fontWeight: LuminaTokens.fontWeightSemibold,
          color: LuminaTokens.darkText,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: LuminaTokens.textMd,
          fontWeight: LuminaTokens.fontWeightRegular,
          color: LuminaTokens.darkText,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: LuminaTokens.textSm,
          fontWeight: LuminaTokens.fontWeightRegular,
          color: LuminaTokens.darkTextMuted,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: LuminaTokens.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: LuminaTokens.borderRadiusMd,
          side: const BorderSide(color: LuminaTokens.darkBorder, width: 1.0),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LuminaTokens.darkSurfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LuminaTokens.spacingMd,
          vertical: LuminaTokens.spacingSm,
        ),
        border: OutlineInputBorder(
          borderRadius: LuminaTokens.borderRadiusMd,
          borderSide: const BorderSide(color: LuminaTokens.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: LuminaTokens.borderRadiusMd,
          borderSide: const BorderSide(color: LuminaTokens.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: LuminaTokens.borderRadiusMd,
          borderSide: const BorderSide(color: LuminaTokens.primary, width: 2.0),
        ),
        labelStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted),
        hintStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted.withOpacity(0.6)),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LuminaTokens.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: LuminaTokens.spacingLg,
            vertical: LuminaTokens.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: LuminaTokens.borderRadiusMd,
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: LuminaTokens.textMd,
            fontWeight: LuminaTokens.fontWeightSemibold,
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: LuminaTokens.darkBorder,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }

  /// Returns light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: LuminaTokens.lightBg,
      primaryColor: LuminaTokens.primary,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: LuminaTokens.primary,
        onPrimary: Colors.white,
        secondary: LuminaTokens.secondary,
        onSecondary: Colors.white,
        error: LuminaTokens.error,
        onError: Colors.white,
        surface: LuminaTokens.lightSurface,
        onSurface: LuminaTokens.lightText,
        outline: LuminaTokens.lightBorder,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: LuminaTokens.textDisplay,
          fontWeight: LuminaTokens.fontWeightBold,
          color: LuminaTokens.lightText,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: LuminaTokens.textXxxl,
          fontWeight: LuminaTokens.fontWeightBold,
          color: LuminaTokens.lightText,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: LuminaTokens.textXl,
          fontWeight: LuminaTokens.fontWeightSemibold,
          color: LuminaTokens.lightText,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: LuminaTokens.textMd,
          fontWeight: LuminaTokens.fontWeightRegular,
          color: LuminaTokens.lightText,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: LuminaTokens.textSm,
          fontWeight: LuminaTokens.fontWeightRegular,
          color: LuminaTokens.lightTextMuted,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: LuminaTokens.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: LuminaTokens.borderRadiusMd,
          side: const BorderSide(color: LuminaTokens.lightBorder, width: 1.0),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LuminaTokens.lightSurfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LuminaTokens.spacingMd,
          vertical: LuminaTokens.spacingSm,
        ),
        border: OutlineInputBorder(
          borderRadius: LuminaTokens.borderRadiusMd,
          borderSide: const BorderSide(color: LuminaTokens.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: LuminaTokens.borderRadiusMd,
          borderSide: const BorderSide(color: LuminaTokens.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: LuminaTokens.borderRadiusMd,
          borderSide: const BorderSide(color: LuminaTokens.primary, width: 2.0),
        ),
        labelStyle: GoogleFonts.inter(color: LuminaTokens.lightTextMuted),
        hintStyle: GoogleFonts.inter(color: LuminaTokens.lightTextMuted.withOpacity(0.6)),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LuminaTokens.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: LuminaTokens.spacingLg,
            vertical: LuminaTokens.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: LuminaTokens.borderRadiusMd,
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: LuminaTokens.textMd,
            fontWeight: LuminaTokens.fontWeightSemibold,
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: LuminaTokens.lightBorder,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
