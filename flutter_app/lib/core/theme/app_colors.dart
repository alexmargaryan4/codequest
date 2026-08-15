import 'package:flutter/material.dart';

/// CodeQuest design tokens.
///
/// Visual direction: "quiet focus" — a calm, editor-inspired palette
/// (deep graphite surfaces, muted indigo accent, restrained mint for
/// success states) rather than the saturated primary-color playfulness
/// of typical language-learning apps. Code is always shown in a
/// monospace face, even inline in the course map, as the app's one
/// consistent signature.
class AppColors {
  const AppColors._();

  // ---- Dark theme (default) ----
  static const Color darkBackground = Color(0xFF12141A);
  static const Color darkSurface = Color(0xFF1B1E27);
  static const Color darkSurfaceRaised = Color(0xFF232733);
  static const Color darkBorder = Color(0xFF2E323F);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // ---- Light theme ----
  static const Color lightBackground = Color(0xFFFAFAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFF3F3F1);
  static const Color lightBorder = Color(0xFFE4E4E1);
  static const Color lightTextPrimary = Color(0xFF15171C);
  static const Color lightTextSecondary = Color(0xFF565A66);
  static const Color lightTextMuted = Color(0xFF8B8F99);

  // ---- Shared accent palette ----
  /// Primary accent — used sparingly for the active node, primary CTA,
  /// and the level/XP progress fill. Muted indigo, not a saturated
  /// "brand purple".
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentIndigoMuted = Color(0xFF4C4FBF);

  /// Success / correct-answer / completed-node color. Restrained mint,
  /// not neon green.
  static const Color success = Color(0xFF34D399);
  static const Color successMuted = Color(0xFF1F9D74);

  /// Error / incorrect-answer color. Warm coral rather than pure red.
  static const Color error = Color(0xFFF87171);

  /// Streak flame accent — warm amber, used only for streak UI so it
  /// stays a distinct, recognizable signal rather than blending into
  /// general warning/error coloring.
  static const Color streakAmber = Color(0xFFF59E0B);

  /// Locked-node / disabled color.
  static const Color lockedGray = Color(0xFF4B5058);

  // Per-language accent seeds (used to tint each course's map/icon so
  /// Python/JS/Dart/C++ feel distinct without leaving the calm palette).
  static const Color pythonAccent = Color(0xFF4C8DFF);
  static const Color javascriptAccent = Color(0xFFE8B339);
  static const Color dartAccent = Color(0xFF34D8C7);
  static const Color cppAccent = Color(0xFF7C8CF8);
  static const Color aiTrackAccent = Color(0xFFB07CF8);

  static Color fromHex(String hex) {
    final String cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
