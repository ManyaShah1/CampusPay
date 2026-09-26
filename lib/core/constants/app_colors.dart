import 'package:flutter/material.dart';

/// Strict design system palette for CampusPay (DBIT Mumbai)
/// Aligned with CampusPay Flutter UI Kit — Stitch design system
class AppColors {
  AppColors._();

  // ── Canvas & Surface (Stitch Neon White) ──────────────────────────────────
  static const Color backgroundWhite       = Color(0xFFFFFFFF); // Stitch: body background #ffffff
  static const Color backgroundCanvas      = Color(0xFFFCF8F8); // Stitch: surface/background #fcf8f8
  static const Color backgroundBlack       = Color(0xFFFFFFFF); // Aliased to white for complete light mode alignment
  static const Color navBackground         = Color(0xFFFFFFFF); // Stitch: surface-container-lowest #ffffff
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Stitch: #ffffff
  static const Color surfaceContainerLow   = Color(0xFFF6F3F2); // Stitch: #f6f3f2 (cards & action tiles)
  static const Color surfaceContainer      = Color(0xFFF0EDEC); // Stitch: #f0edec (pills & inputs)
  static const Color cardDark              = Color(0xFFF6F3F2); // Elevation 1 card surface
  static const Color cardDarker            = Color(0xFFF0EDEC);
  static const Color surfaceContainerHigh  = Color(0xFFEBE7E7); // Stitch: #ebe7e7
  static const Color surfaceContainerHighest = Color(0xFFE5E2E1); // Stitch: #e5e2e1
  static const Color surfaceBright         = Color(0xFFFCF8F8);
  static const Color surfaceDim            = Color(0xFFDCD9D9);

  // ── Strokes & Dividers ───────────────────────────────────────────────────
  static const Color borderStroke          = Color(0xFFE5E2E1); // Structural 1px subtle stroke
  static const Color borderSubtle          = Color(0xFFF0EDEC);
  static const Color outline               = Color(0xFF7D775F);
  static const Color outlineVariant        = Color(0xFFCEC7AA);

  // ── Brand Palette (Neo-Brutalist Pop) ────────────────────────────────────
  static const Color electricYellow        = Color(0xFFFFE500); // Primary kinetic driver
  static const Color electricYellowDim     = Color(0xFFDEC800);
  static const Color onElectricYellow      = Color(0xFF1C1B1B); // High AAA contrast black
  static const Color deepPurple            = Color(0xFF6B21A8); // Offline crypto resilience
  static const Color deepPurpleAlt         = Color(0xFF803ABD); // Stitch: secondary #803abd
  static const Color royalPurple           = Color(0xFF4C1D95);
  static const Color lightPurple           = Color(0xFF803ABD); // Secondary micro-interactions
  static const Color lightPurpleDim        = Color(0xFFDFB7FF);
  static const Color secondaryContainer    = Color(0xFFC17BFF);
  static const Color secondaryFixed        = Color(0xFFF1DBFF); // Chip background in Stitch
  static const Color onSecondaryFixed      = Color(0xFF2D0050);
  static const Color tertiary              = Color(0xFF842BD2);
  static const Color tertiaryContainer     = Color(0xFFF1DCFF);
  static const Color onTertiaryContainer   = Color(0xFF8B34D9);

  // ── Typography & Base Contrast Colors ────────────────────────────────────
  static const Color white                 = Color(0xFFFFFFFF);
  static const Color onSurface             = Color(0xFF1C1B1B); // Stitch: text-on-surface #1c1b1b
  static const Color onSurfaceVariant      = Color(0xFF4B4731); // Stitch: text-on-surface-variant #4b4731
  static const Color mutedText             = Color(0xFF7D775F);
  static const Color lightMutedText       = Color(0xFF9E9A8A);

  // ── Semantic Feedback ────────────────────────────────────────────────────
  static const Color successGreen         = Color(0xFF16A34A); // Terminal Green sync confirmed
  static const Color tealAccent           = Color(0xFF0D9488);
  static const Color amberAccent          = Color(0xFFD97706);
  static const Color redAccent            = Color(0xFFDC2626);
  static const Color errorContainer       = Color(0xFFFFDAD6);
  static const Color errorRed             = Color(0xFFBA1A1A);

  // ── Gradients ────────────────────────────────────────────────────────────
  /// Stitch ID-1 Aspect Ratio Hero Wallet Card Gradient
  static const LinearGradient walletHeroGradient = LinearGradient(
    colors: [Color(0xFF6B21A8), Color(0xFF581C87), Color(0xFF4C1D95)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Electric yellow kinetic button gradient
  static const LinearGradient yellowGlowGradient = LinearGradient(
    colors: [Color(0xFFFFE500), Color(0xFFDEC800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Purple security status gradient
  static const LinearGradient purpleGlowGradient = LinearGradient(
    colors: [Color(0xFF6B21A8), Color(0xFFC084FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Wallet pass card gradient
  static const LinearGradient cardPassGradient = LinearGradient(
    colors: [Color(0xFFF6F3F2), Color(0xFFF1DBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// CampusCoins rewards gradient (Stitch: tertiary-container -> secondary-fixed -> primary-container)
  static const LinearGradient rewardsHeroGradient = LinearGradient(
    colors: [Color(0xFFF1DCFF), Color(0xFFF1DBFF), Color(0xFFFFF7C2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Box Shadows & Ambient Glows ──────────────────────────────────────────
  static List<BoxShadow> get cardElevation => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      spreadRadius: -2,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get yellowGlow => [
    BoxShadow(
      color: electricYellow.withValues(alpha: 0.45),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get yellowNeonIntense => [
    BoxShadow(
      color: electricYellow.withValues(alpha: 0.55),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get purpleGlow => [
    BoxShadow(
      color: deepPurple.withValues(alpha: 0.38),
      blurRadius: 32,
      spreadRadius: -8,
      offset: const Offset(0, 16),
    ),
  ];
}
