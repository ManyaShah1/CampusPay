import 'package:flutter/material.dart';

/// Strict design system palette for CampusPay (DBIT Mumbai)
class AppColors {
  AppColors._();

  // Primary brand palette
  static const Color backgroundBlack = Color(0xFF0A0A0A);
  static const Color electricYellow = Color(0xFFFFE500);
  static const Color deepPurple = Color(0xFF6B21A8);
  static const Color lightPurple = Color(0xFFC084FC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1A1A1A);
  static const Color cardDarker = Color(0xFF141414);
  static const Color borderStroke = Color(0xFF2A2A2A);
  static const Color borderSubtle = Color(0xFF333333);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color mutedText = Color(0xFF888888);
  static const Color lightMutedText = Color(0xFFCCCCCC);

  // Functional accents
  static const Color tealAccent = Color(0xFF14B8A6);
  static const Color amberAccent = Color(0xFFF59E0B);
  static const Color redAccent = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient yellowGlowGradient = LinearGradient(
    colors: [Color(0xFFFFE500), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGlowGradient = LinearGradient(
    colors: [Color(0xFF6B21A8), Color(0xFFC084FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0xFF1F1F1F), Color(0xFF141414)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
