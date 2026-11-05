import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Ergonomic constants from the UX spec.
abstract final class AppDimens {
  /// Minimum touch target (44x44).
  static const double minTouch = 44;

  /// Bottom-fixed CTA button height.
  static const double ctaHeight = 52;
}

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: brightness)
        .copyWith(primary: AppColors.primary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(AppDimens.ctaHeight)),
          textStyle: const WidgetStatePropertyAll(AppTypography.button),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? AppColors.primaryPressed : AppColors.primary,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppDimens.minTouch, AppDimens.minTouch),
        ),
      ),
    );
  }
}
