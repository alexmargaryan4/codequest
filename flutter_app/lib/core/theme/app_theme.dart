import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Consistent corner radii used across the app: soft but not childish.
/// Cards and large surfaces use [radiusLg]; buttons and chips use
/// [radiusMd]; small inline elements (badges, pills) use [radiusSm].
class AppRadius {
  const AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

class AppSpacing {
  const AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme.dark(
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkTextPrimary,
      primary: AppColors.accentIndigo,
      onPrimary: Colors.white,
      secondary: AppColors.success,
      onSecondary: Colors.black,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _build(
      scheme: scheme,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      surfaceRaised: AppColors.darkSurfaceRaised,
      border: AppColors.darkBorder,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      brightness: Brightness.dark,
    );
  }

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme.light(
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightTextPrimary,
      primary: AppColors.accentIndigo,
      onPrimary: Colors.white,
      secondary: AppColors.successMuted,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _build(
      scheme: scheme,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      surfaceRaised: AppColors.lightSurfaceRaised,
      border: AppColors.lightBorder,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
      brightness: Brightness.light,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color surface,
    required Color surfaceRaised,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Brightness brightness,
  }) {
    final TextTheme textTheme = AppTypography.textTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentIndigo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.lockedGray,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentIndigo,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceRaised,
        side: BorderSide(color: border),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentIndigo,
        linearTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.accentIndigo,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.accentIndigo.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? AppColors.accentIndigo : textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppSemanticColors(
          surfaceRaised: surfaceRaised,
          border: border,
          success: AppColors.success,
          error: AppColors.error,
          streak: AppColors.streakAmber,
          locked: AppColors.lockedGray,
          textMuted: brightness == Brightness.dark
              ? AppColors.darkTextMuted
              : AppColors.lightTextMuted,
        ),
      ],
    );
  }
}

/// Extra semantic colors not covered by [ColorScheme], accessible via
/// `Theme.of(context).extension<AppSemanticColors>()`.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.surfaceRaised,
    required this.border,
    required this.success,
    required this.error,
    required this.streak,
    required this.locked,
    required this.textMuted,
  });

  final Color surfaceRaised;
  final Color border;
  final Color success;
  final Color error;
  final Color streak;
  final Color locked;
  final Color textMuted;

  @override
  AppSemanticColors copyWith({
    Color? surfaceRaised,
    Color? border,
    Color? success,
    Color? error,
    Color? streak,
    Color? locked,
    Color? textMuted,
  }) {
    return AppSemanticColors(
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      success: success ?? this.success,
      error: error ?? this.error,
      streak: streak ?? this.streak,
      locked: locked ?? this.locked,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ThemeExtension<AppSemanticColors> lerp(
    ThemeExtension<AppSemanticColors>? other,
    double t,
  ) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
      locked: Color.lerp(locked, other.locked, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}
