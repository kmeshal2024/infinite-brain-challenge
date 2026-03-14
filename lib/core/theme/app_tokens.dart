import 'package:flutter/material.dart';

/// ─── COLOR PALETTE ─────────────────────────────────────────────
/// Premium dark theme with vibrant accents
class AppColors {
  AppColors._();

  // Base surfaces
  static const Color background = Color(0xFF0D0F1A);
  static const Color surface = Color(0xFF161929);
  static const Color surfaceLight = Color(0xFF1E2238);
  static const Color surfaceCard = Color(0xFF222640);
  static const Color surfaceElevated = Color(0xFF2A2F4A);

  // Primary accent - electric blue
  static const Color primary = Color(0xFF4C7CF7);
  static const Color primaryLight = Color(0xFF7BA3FF);
  static const Color primaryDark = Color(0xFF2B5BD4);
  static const Color primarySurface = Color(0xFF1A2A5E);

  // Secondary accent - vibrant coral
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF9E9E);
  static const Color accentDark = Color(0xFFD44444);

  // Tertiary - golden yellow for rewards
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFE44D);
  static const Color goldDark = Color(0xFFC5A600);
  static const Color goldSurface = Color(0xFF3D3200);

  // Success / Correct
  static const Color success = Color(0xFF4ADE80);
  static const Color successDark = Color(0xFF22C55E);
  static const Color successSurface = Color(0xFF0D3320);

  // Error / Wrong
  static const Color error = Color(0xFFFF5252);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color errorSurface = Color(0xFF3D1111);

  // Warning
  static const Color warning = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  // Text hierarchy
  static const Color textPrimary = Color(0xFFF0F2FF);
  static const Color textSecondary = Color(0xFFB0B8D4);
  static const Color textTertiary = Color(0xFF6E7699);
  static const Color textDisabled = Color(0xFF4A4F6A);

  // Category colors for mini-games
  static const Color memoryColor = Color(0xFF7C6FFF);
  static const Color logicColor = Color(0xFF4CC9F0);
  static const Color speedColor = Color(0xFFFF6B6B);
  static const Color mathColor = Color(0xFF4ADE80);
  static const Color patternColor = Color(0xFFFFB74D);
  static const Color puzzleColor = Color(0xFFE879F9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4C7CF7), Color(0xFF7C6FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF9E6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF4CC9F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF161929), Color(0xFF1E2238)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D0F1A), Color(0xFF131628)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// ─── SPACING SCALE ─────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;
  static const double giant = 64.0;
}

/// ─── RADIUS SCALE ──────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double round = 100.0;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get roundAll => BorderRadius.circular(round);
}

/// ─── SHADOWS ───────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> glowColor(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ];
}

/// ─── ANIMATION DURATIONS ───────────────────────────────────────
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration splash = Duration(milliseconds: 800);
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration gameReveal = Duration(milliseconds: 600);
  static const Duration celebration = Duration(milliseconds: 1200);
}

/// ─── ICON SIZES ────────────────────────────────────────────────
class AppIconSize {
  AppIconSize._();

  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double huge = 56.0;
}
