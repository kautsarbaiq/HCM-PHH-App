import 'package:flutter/material.dart';

import '../core/config/brand.dart';

/// Design tokens, branched per brand at COMPILE time (Brand.isPhh is a
/// compile-time constant, so every `Brand.isPhh ? a : b` below stays a valid
/// const expression):
///
///  - PHH Housing   : the original bright indigo-violet palette.
///  - Home Cloud Asia: palette derived from the HCA logo — ocean teal
///    (#40A0C0–#50C0D0) + deep navy (#001040–#002060).
class AppColors {
  // ---- Surfaces (bright & airy) ----
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Brand.isPhh
      ? Color(0xFFF5F7FF) // light lilac canvas
      : Color(0xFFF3F8FB); // light sky canvas
  static const Color surfaceTint = Brand.isPhh
      ? Color(0xFFF1F4FF)
      : Color(0xFFEEF5F9);
  static const Color surfaceSky = Brand.isPhh
      ? Color(0xFFEFF6FF)
      : Color(0xFFE8F4F9);

  // ---- Brand / primary ----
  static const Color primaryBlue = Brand.isPhh
      ? Color(0xFF0EA5E9) // resident sky
      : Color(0xFF2FA8C7); // logo teal
  static const Color brand = Brand.isPhh
      ? Color(0xFF5B6CFF) // bright indigo
      : Color(0xFF14508C); // logo navy-blue
  static const Color brandViolet = Brand.isPhh
      ? Color(0xFF8E7BFF)
      : Color(0xFF2F7EB5);
  static const Color deepSlate = Brand.isPhh
      ? Color(0xFF2B2D42)
      : Color(0xFF16335E);

  // ---- Vivid accents ----
  static const Color accentSky = Brand.isPhh
      ? Color(0xFF38BDF8)
      : Color(0xFF4FC3DF);
  static const Color accentCyan = Brand.isPhh
      ? Color(0xFF22D3EE)
      : Color(0xFF38B6D6);
  static const Color accentMint = Color(0xFF34D399);
  static const Color accentAmber = Color(0xFFFBBF24);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentCoral = Color(0xFFFF7A6B);

  /// Lime-yellow highlight used behind HCA duotone icons (the "sticker" fill
  /// from the reference design).
  static const Color duotoneFill = Color(0xFFF2E76B);

  // ---- Text ----
  static const Color textPrimary = Brand.isPhh
      ? Color(0xFF1B2559) // deep indigo-navy
      : Color(0xFF0E2A52); // logo navy
  static const Color textSecondary = Brand.isPhh
      ? Color(0xFF8A93B8)
      : Color(0xFF7B8BA8);
  static const Color textLight = Color(0xFFFFFFFF);

  // ---- Status ----
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Brand.isPhh ? Color(0xFF3B82F6) : Color(0xFF2F7EB5);

  // ---- Glass ----
  static const Color glassWhite = Color(0x99FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ---- Shadows ----
  static const Color shadowColor = Color(0x0F000000); // 6% black
  static const Color brandShadow = Brand.isPhh
      ? Color(0x335B6CFF)
      : Color(0x3314508C);

  // ---- Gradients ----
  static const LinearGradient brandGradient = Brand.isPhh
      ? LinearGradient(
          colors: [Color(0xFF5B6CFF), Color(0xFF8E7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : LinearGradient(
          colors: [Color(0xFF38B1D2), Color(0xFF123B6D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
  static const LinearGradient skyGradient = Brand.isPhh
      ? LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : LinearGradient(
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
  static const LinearGradient canvasGradient = Brand.isPhh
      ? LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFEFF1FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      : LinearGradient(
          colors: [Color(0xFFF8FCFE), Color(0xFFEAF3F8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
}
