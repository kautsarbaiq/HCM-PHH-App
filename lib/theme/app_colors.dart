import 'package:flutter/material.dart';

/// Design tokens derived from the Home Cloud Asia logo: ocean teal
/// (#40A0C0–#50C0D0) + deep navy (#001040–#002060) on bright, airy surfaces.
/// Token names are preserved so every screen keeps compiling — changing the
/// values here re-skins the whole app.
class AppColors {
  // ---- Surfaces (bright & airy, cool blue tint) ----
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Color(0xFFF3F8FB); // light sky canvas
  static const Color surfaceTint = Color(0xFFEEF5F9); // soft card tint
  static const Color surfaceSky = Color(0xFFE8F4F9); // soft sky tint

  // ---- Brand / primary (logo ocean blue + navy) ----
  static const Color primaryBlue = Color(0xFF2FA8C7); // logo teal
  static const Color brand = Color(0xFF14508C); // logo navy-blue
  static const Color brandViolet = Color(0xFF2F7EB5); // logo mid blue
  static const Color deepSlate = Color(0xFF16335E);

  // ---- Vivid accents (teal family from the logo) ----
  static const Color accentSky = Color(0xFF4FC3DF);
  static const Color accentCyan = Color(0xFF38B6D6);
  static const Color accentMint = Color(0xFF34D399);
  static const Color accentAmber = Color(0xFFFBBF24);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentCoral = Color(0xFFFF7A6B);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF0E2A52); // logo navy
  static const Color textSecondary = Color(0xFF7B8BA8);
  static const Color textLight = Color(0xFFFFFFFF);

  // ---- Status ----
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2F7EB5);

  // ---- Glass ----
  static const Color glassWhite = Color(0x99FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ---- Shadows ----
  static const Color shadowColor = Color(0x0F000000); // 6% black
  static const Color brandShadow = Color(0x3314508C); // tinted navy glow

  // ---- Gradients ----
  /// Logo gradient: light teal → deep navy.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF38B1D2), Color(0xFF123B6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient skyGradient = LinearGradient(
    colors: [Color(0xFF4FC3DF), Color(0xFF2FA8C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFFB7185)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Very subtle bright page-background wash.
  static const LinearGradient canvasGradient = LinearGradient(
    colors: [Color(0xFFF8FCFE), Color(0xFFEAF3F8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
