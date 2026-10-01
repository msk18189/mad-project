import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography configuration for DEADLINE
/// "Editorial + Playful + Tactile + Time-focused"
class AppTypography {
  AppTypography._();

  // Primary heading font: Space Grotesk
  static TextStyle get displayLarge => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.ink,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: AppColors.ink,
        height: 1.15,
      );

  static TextStyle get titleLarge => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.ink,
      );

  static TextStyle get titleMedium => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.ink,
      );

  static TextStyle get titleSmall => GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  // Body font: Inter / Manrope
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.4,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        height: 1.4,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.mutedGrey,
        height: 1.3,
      );

  // Countdown & Time font: Tabular Numbers
  static TextStyle get countdownHero => GoogleFonts.spaceGrotesk(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: AppColors.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get countdownMedium => GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: AppColors.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get countdownSmall => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Editorial Stamp & Badge font
  static TextStyle get stamp => GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: AppColors.ink,
      );

  static TextStyle get badge => GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.ink,
      );

  static TextStyle get monoMedium => GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get monoSmall => GoogleFonts.spaceGrotesk(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Rare handwritten annotation font (Caveat) - used strictly for tiny notes
  static TextStyle get handwritten => GoogleFonts.caveat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.burntOrange,
      );
}
