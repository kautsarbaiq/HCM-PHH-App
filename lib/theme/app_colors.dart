import 'package:flutter/material.dart';

/// Bright, premium design tokens. The palette is intentionally light and airy
/// (white / soft-lilac surfaces) with vivid, saturated accents and gradients —
/// no dark backgrounds. Existing token names are preserved so older screens
/// keep compiling; new tokens add the brighter, bolder language.
class AppColors {
  // ---- Surfaces (bright & airy) ----
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Color(0xFFF5F7FF); // light lilac canvas
  static const Color surfaceTint = Color(0xFFF1F4FF); // soft card tint
  static const Color surfaceSky = Color(0xFFEFF6FF); // soft sky tint

  // ---- Brand / primary (vivid but bright indigo-violet) ----
  static const Color primaryBlue = Color(0xFF0EA5E9); // kept (resident sky)
  static const Color brand = Color(0xFF5B6CFF); // new unifying bright indigo
  static const Color brandViolet = Color(0xFF8E7BFF);
  static const Color deepSlate = Color(0xFF2B2D42);

  // ---- Vivid accents ----
  static const Color accentSky = Color(0xFF38BDF8);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentMint = Color(0xFF34D399);
  static const Color accentAmber = Color(0xFFFBBF24);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentCoral = Color(0xFFFF7A6B);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF1B2559); // deep indigo-navy
  static const Color textSecondary = Color(0xFF8A93B8);
  static const Color textLight = Color(0xFFFFFFFF);

  // ---- Status ----
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ---- Glass ----
  static const Color glassWhite = Color(0x99FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ---- Shadows ----
  static const Color shadowColor = Color(0x0F000000); // 6% black
  static const Color brandShadow = Color(0x335B6CFF); // tinted brand glow

  // ---- Gradients ----
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF5B6CFF), Color(0xFF8E7BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient skyGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF38BDF8)],
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
    colors: [Color(0xFFF8FAFF), Color(0xFFEFF1FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
