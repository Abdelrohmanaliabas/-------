import 'package:flutter/material.dart';

/// App color palette designed for a luxury dark modern Arabic music streaming experience.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF111726);
  static const Color surfaceLight = Color(0xFF1B2337);
  static const Color surfaceCard = Color(0xFF161F33);
  static const Color cardGlass = Color(0x2A2C3E5F);

  // Accents & Primaries (Modern Electric Cyan & Vibrant Coral Violet)
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryLight = Color(0xFF6EFAFF);
  static const Color primaryDark = Color(0xFF00B0FF);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFFF3366);
  static const Color gold = Color(0xFFFFB300);

  // Player & Controls
  static const Color playerGlow = Color(0x3300E5FF);
  static const Color progressBarActive = Color(0xFF00E5FF);
  static const Color progressBarBuffered = Color(0x40FFFFFF);
  static const Color progressBarInactive = Color(0x1FFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFF334155);

  // Status & Utility
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color divider = Color(0xFF1E293B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1B243B), Color(0xFF111726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient playerBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFF131D38),
      Color(0xFF090D16),
      Color(0xFF05070D),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkFadeGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xFF090D16)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
