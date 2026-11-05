import 'package:flutter/material.dart';

/// Pretendard type scale. The family falls back to the platform font until the font files are
/// added to pubspec.yaml (see the commented `fonts:` block).
abstract final class AppTypography {
  static const String fontFamily = 'Pretendard';

  static const TextStyle display = TextStyle(fontFamily: fontFamily, fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w700);
  static const TextStyle headline = TextStyle(fontFamily: fontFamily, fontSize: 22, height: 30 / 22, fontWeight: FontWeight.w700);
  static const TextStyle title = TextStyle(fontFamily: fontFamily, fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(fontFamily: fontFamily, fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400);
  static const TextStyle bodyStrong = TextStyle(fontFamily: fontFamily, fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w600);
  static const TextStyle caption = TextStyle(fontFamily: fontFamily, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400);
  static const TextStyle button = TextStyle(fontFamily: fontFamily, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600);

  static TextTheme get textTheme => const TextTheme(
        displaySmall: display,
        headlineSmall: headline,
        titleMedium: title,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: button,
      );
}
