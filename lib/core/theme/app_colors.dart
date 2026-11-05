import 'package:flutter/material.dart';

/// Text + light/dark surface colours for one availability state.
class StatusTone {
  const StatusTone({required int text, required int surfaceLight, required int surfaceDark})
      : _text = text,
        _surfaceLight = surfaceLight,
        _surfaceDark = surfaceDark;

  final int _text;
  final int _surfaceLight;
  final int _surfaceDark;

  Color get text => Color(0xFF000000 | _text);
  Color surface(Brightness brightness) =>
      Color(0xFF000000 | (brightness == Brightness.dark ? _surfaceDark : _surfaceLight));

  /// `#RRGGBB`, for the HTML map overlays.
  String get textHex => _hex(_text);
  String get surfaceLightHex => _hex(_surfaceLight);
  String get surfaceDarkHex => _hex(_surfaceDark);

  static String _hex(int rgb) => '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Colour semantics from the UX spec.
abstract final class AppColors {
  static const Color primary = Color(0xFF00A86B);
  static const Color primaryPressed = Color(0xFF008F5B);

  /// 4 or more bikes.
  static const StatusTone available =
      StatusTone(text: 0x22C55E, surfaceLight: 0xF0FDF4, surfaceDark: 0x052E16);

  /// 1~3 bikes.
  static const StatusTone warning =
      StatusTone(text: 0xF59E0B, surfaceLight: 0xFFFBEB, surfaceDark: 0x451A03);

  /// 0 bikes.
  static const StatusTone danger =
      StatusTone(text: 0xEF4444, surfaceLight: 0xFEF2F2, surfaceDark: 0x450A0A);

  /// Unknown / closed station / no data.
  static const StatusTone disabled =
      StatusTone(text: 0x9CA3AF, surfaceLight: 0xF3F4F6, surfaceDark: 0x1F2937);

  /// Maps a bike count to its tone; `null` (no data) is disabled.
  static StatusTone toneFor(int? bikeCount) {
    if (bikeCount == null || bikeCount < 0) return disabled;
    if (bikeCount == 0) return danger;
    if (bikeCount <= 3) return warning;
    return available;
  }
}
