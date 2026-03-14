import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

/// ─── TYPOGRAPHY SYSTEM ─────────────────────────────────────────
/// Using Nunito via google_fonts for its friendly, rounded personality
/// that suits a brain-training game while remaining highly readable.
class AppTypography {
  AppTypography._();

  // ── Display ──
  static TextStyle get displayLarge => GoogleFonts.nunito(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.15,
        color: AppColors.textPrimary,
      );

  static TextStyle get displaySmall => GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  // ── Headings ──
  static TextStyle get headingLarge => GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingMedium => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingSmall => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  // ── Body ──
  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textTertiary,
      );

  // ── Labels ──
  static TextStyle get labelLarge => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.nunito(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColors.textTertiary,
      );

  // ── Game-specific ──
  static TextStyle get gameScore => GoogleFonts.nunito(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.0,
        color: AppColors.gold,
      );

  static TextStyle get gameTimer => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        height: 1.0,
        color: AppColors.textPrimary,
      );

  static TextStyle get gameFeedback => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get coinText => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.gold,
      );

  static TextStyle get buttonText => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        height: 1.0,
        color: AppColors.textPrimary,
      );
}
