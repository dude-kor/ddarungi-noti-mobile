import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/station/domain/station.dart';

/// Availability pill: surface + text colours follow the spec thresholds (>=4 / 1~3 / 0 / unknown).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.bikeCount, this.label});

  final int? bikeCount;

  /// Overrides the default wording (see [availabilityLabel]).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final tone = AppColors.toneFor(bikeCount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.surface(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.text),
      ),
      child: Text(
        label ?? availabilityLabel(bikeCount),
        style: TextStyle(color: tone.text, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
