import 'package:flutter/material.dart';

/// Semantic Color Palette for DEADLINE
/// Editorial + Playful + Tactile + Time-Focused
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color paper = Color(0xFFF4F0E8);          // Warm Paper Background
  static const Color ink = Color(0xFF20211E);            // Ink Black
  static const Color burntOrange = Color(0xFFD95D39);     // Burnt Orange (High Priority / Urgency)
  static const Color petrolBlue = Color(0xFF294C60);      // Deep Petrol Blue
  static const Color mustard = Color(0xFFE7B84B);         // Muted Mustard (Medium Priority)
  static const Color oliveGreen = Color(0xFF617A55);      // Olive Green (Low Priority / Completed)
  static const Color warning = Color(0xFFD18B32);         // Warning
  static const Color danger = Color(0xFFC83E3E);          // Critical / Missed
  static const Color softWhite = Color(0xFFFFFDF7);       // Soft White Card Surface
  static const Color mutedGrey = Color(0xFF8C8A82);       // Editorial Secondary Text
  static const Color lightBorder = Color(0xFFE2DDD1);     // Subtle Ticket Divider
  static const Color darkBorder = Color(0xFF333530);      // Dark Mode Border

  // Dark Theme Palette (Maintains Editorial Identity)
  static const Color darkPaper = Color(0xFF181916);       // Dark Ink Paper Background
  static const Color darkCard = Color(0xFF242622);        // Dark Charcoal Surface
  static const Color darkInk = Color(0xFFF2EFE9);         // Inverted Text Ink
  static const Color darkMuted = Color(0xFF9E9C94);       // Muted Dark Text
  static const Color darkAccent = Color(0xFFE0724F);      // Slightly boosted orange for dark mode

  // Priority Colors
  static const Color priorityLow = oliveGreen;
  static const Color priorityMedium = mustard;
  static const Color priorityHigh = burntOrange;
  static const Color priorityCritical = danger;

  // Sticky Note Colors
  static const Color stickyYellow = Color(0xFFFFF7C2);
  static const Color stickyBlue = Color(0xFFE2F0F9);
  static const Color stickyPink = Color(0xFFFFE5E5);
  static const Color stickyGreen = Color(0xFFE5F5E0);
}
