import 'package:flutter/material.dart';

class AppColors {
  // Primary & Secondary Brand Colors (curated Slate Navy & Modern Indigo)
  static const Color primary = Color(0xFF2E3B5C);      // Slate Navy Blue
  static const Color primaryAccent = Color(0xFF4A62A0); // Modern Indigo
  static const Color secondary = Color(0xFF0F172A);    // Dark Charcoal Slate

  // Status & Utility Colors (curated harmony, not plain solid colors)
  static const Color success = Color(0xFF10B981);      // Soft Emerald Green
  static const Color error = Color(0xFFEF4444);        // Soft Rose Red
  static const Color warning = Color(0xFFF59E0B);      // Soft Amber Yellow
  static const Color info = Color(0xFF3B82F6);         // Clean Blue
  static const Color accent = Color(0xFF8B5CF6);       // Modern Purple

  // Curated Solid Colors (For compatibility with existing widgets)
  static const Color orange = Color(0xFFF97316);       // Curated Amber Orange
  static const Color blue = Color(0xFF3B82F6);         // Curated Royal Blue
  static const Color grey = Color(0xFF64748B);         // Curated Slate Grey
  static const Color purple = Color(0xFF8B5CF6);       // Curated Purple
  static const Color teal = Color(0xFF14B8A6);         // Curated Teal

  // Backgrounds & Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF020617);        // Rich black
  static const Color lightGrey = Color(0xFFF8FAFC);    // Soft Slate Grey
  static const Color darkGrey = Color(0xFF475569);     // Mid Slate Grey
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);     // Slate Card Dark

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E3B5C), Color(0xFF4A62A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Opacity helper getters
  static Color get primaryOp10 => primary.withValues(alpha: 0.1);
  static Color get successOp10 => success.withValues(alpha: 0.1);
  static Color get errorOp10 => error.withValues(alpha: 0.1);
  static Color get warningOp10 => warning.withValues(alpha: 0.1);
}
