import '../theme/app_colors.dart';

/// HTML for the status-coloured pill that shows the live bike count on the Kakao map
/// (use as the `content` of a `CustomOverlay`, anchored at the pill's bottom centre).
abstract final class StationMarkerHtml {
  static String pill({required int? bikeCount, bool selected = false}) {
    final tone = AppColors.toneFor(bikeCount);
    final label = (bikeCount == null || bikeCount < 0) ? '-' : '$bikeCount';
    final border = selected ? '#00A86B' : tone.textHex;
    final scale = selected ? 1.15 : 1.0;
    // Overlays sit on the map tiles (light), so the light surface is always used.
    return '<div style="min-width:36px;padding:4px 10px;border-radius:999px;'
        'background:${tone.surfaceLightHex};color:${tone.textHex};border:2px solid $border;'
        'font:700 14px/1.2 Pretendard,-apple-system,sans-serif;text-align:center;'
        'box-shadow:0 1px 4px rgba(0,0,0,.25);transform:scale($scale);">$label</div>';
  }
}
