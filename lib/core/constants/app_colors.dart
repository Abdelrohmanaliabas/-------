import 'package:flutter/material.dart';

/// App color palette designed for a luxury dark modern Arabic music streaming experience.
class AppColors {
  AppColors._();

  // Backgrounds (YouTube Music Pure Dark)
  static const Color background = Color(0xFF030303);
  static const Color surface = Color(0xFF0F0F0F);
  static const Color surfaceLight = Color(0xFF212121);
  static const Color surfaceCard = Color(0xFF1E1E1E);
  static const Color cardGlass = Color(0x33282828);

  // YouTube Music Red & Pure White
  static const Color ytRed = Color(0xFFFF0000);
  static const Color primary = Colors.white; // Active controls & text are crisp white
  static const Color primaryLight = Color(0xFFEEEEEE);
  static const Color primaryDark = Color(0xFFCCCCCC);
  static const Color secondary = Color(0xFFFF0000); // Red accent
  static const Color accent = Color(0xFFFF0000);
  static const Color gold = Color(0xFFFFB300);

  // Filter chips & pills
  static const Color chipBackground = Color(0xFF212121);
  static const Color chipBorder = Color(0xFF383838);
  static const Color pillActionBackground = Color(0xFF272727);

  // Player & Controls (YouTube Music)
  static const Color playerGlow = Color(0x22FFFFFF);
  static const Color progressBarActive = Colors.white;
  static const Color progressBarBuffered = Color(0x40FFFFFF);
  static const Color progressBarInactive = Color(0x25FFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF717171);
  static const Color textDark = Color(0xFF333333);

  // Status & Utility
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFFF0000);
  static const Color divider = Color(0xFF242424);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF282828), Color(0xFF181818)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF212121), Color(0xFF141414)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient playerBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFF0D0D0D),
      Color(0xFF030303),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkFadeGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xFF030303)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
