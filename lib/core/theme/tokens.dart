import 'package:flutter/material.dart';

/// Lumina Design System Tokens
/// Consumed globally by the user mobile application.
class LuminaTokens {
  LuminaTokens._();

  static const String brandName = "Lumina";
  static const String brandVersion = "1.0.0";

  // ==========================================
  // Brand Colors
  // ==========================================
  
  // Primary (Electric Indigo / Violet)
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryGlow = Color(0x664F46E5);

  // Secondary (Cyber Magenta / Pink)
  static const Color secondaryLight = Color(0xFFF472B6);
  static const Color secondary = Color(0xFFEC4899);
  static const Color secondaryDark = Color(0xFFBE185D);
  static const Color secondaryGlow = Color(0x66EC4899);

  // Accent (Warm Amber)
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFB45309);
  static const Color accentGlow = Color(0x66F59E0B);

  // Semantic Status Colors
  static const Color successLight = Color(0xFF34D399);
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF065F46);

  static const Color errorLight = Color(0xFFF87171);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFF991B1B);

  // Neutral Theme Colors (Dark Theme First - Obsidian System)
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceSecondary = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF475569);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Neutral Theme Colors (Light Theme)
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);

  // ==========================================
  // Gradients
  // ==========================================
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final Gradient glassGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.08),
      Colors.white.withOpacity(0.03),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================
  // Spacing (Base 4px system)
  // ==========================================
  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  static const double spacingXxxl = 64.0;

  // ==========================================
  // Border Radius
  // ==========================================
  static const double radiusNone = 0.0;
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 9999.0;

  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // ==========================================
  // Typography Font Names
  // ==========================================
  static const String fontHeadings = "Outfit";
  static const String fontBody = "Inter";

  // Typography Sizes
  static const double textXs = 12.0;
  static const double textSm = 14.0;
  static const double textMd = 16.0;
  static const double textLg = 18.0;
  static const double textXl = 20.0;
  static const double textXxl = 24.0;
  static const double textXxxl = 32.0;
  static const double textDisplay = 48.0;

  // Typography Font Weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // ==========================================
  // Shadows & Ambient Glows
  // ==========================================
  static final List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: const Offset(0, 2),
      blurRadius: 8,
    )
  ];

  static final List<BoxShadow> shadowElevated = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      offset: const Offset(0, 8),
      blurRadius: 24,
    )
  ];

  static final List<BoxShadow> shadowGlowPrimary = [
    BoxShadow(
      color: const Color(0xFF4F46E5).withOpacity(0.25),
      offset: Offset.zero,
      blurRadius: 20,
    )
  ];

  static final List<BoxShadow> shadowGlowSecondary = [
    BoxShadow(
      color: const Color(0xFFEC4899).withOpacity(0.25),
      offset: Offset.zero,
      blurRadius: 20,
    )
  ];

  static final List<BoxShadow> shadowGlass = [
    BoxShadow(
      color: Colors.black.withOpacity(0.37),
      offset: const Offset(0, 8),
      blurRadius: 32,
    )
  ];
}
