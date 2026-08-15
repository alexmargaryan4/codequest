import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type system: Manrope for UI (geometric, modern, highly legible at
/// small sizes), JetBrains Mono for all code — the app's one consistent
/// signature element, used not just in exercises but inline in lesson
/// titles and course-map labels whenever a code token is referenced.
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Color primary, Color secondary) {
    final TextStyle base = GoogleFonts.manrope(color: primary);

    return TextTheme(
      displayLarge: base.copyWith(fontSize: 34, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.5),
      displayMedium: base.copyWith(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.3),
      headlineLarge: base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
      headlineMedium: base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
      titleLarge: base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
      titleMedium: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
      bodyLarge: base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: primary),
      bodyMedium: base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: secondary),
      bodySmall: base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, color: secondary),
      labelLarge: base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelMedium: base.copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      labelSmall: base.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: secondary),
    );
  }

  /// Monospace style for code snippets, inline code tokens, and
  /// code-completion exercises.
  static TextStyle code({
    required Color color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.jetBrainsMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.5,
    );
  }
}
