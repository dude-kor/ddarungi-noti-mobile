import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/status_pill.dart';
import '../../favorites/data/favorite_repository.dart';
import '../domain/station.dart';

/// Content of the draggable bottom sheet on [HomeMapScreen] (SCR-03): name, No. badge, status pill,
/// capacity bar, details and the "도착 전 알림 받기" CTA.
class StationSheet extends ConsumerWidget {
  const StationSheet({
    super.key,
    required this.station,
    required this.scrollController,
    required this.onAlert,
    required this.onClose,
  });

  final Station station;
  final ScrollController scrollController;
  final VoidCallback onAlert;
  final VoidCallback onClose;

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, bool isFavorite) async {
    final repo = ref.read(favoriteRepositoryProvider);
    try {
      if (isFavorite) {
        await repo.remove(station.stationId);
      } else {
        await repo.add(station.stationId);
      }
      ref.invalidate(favoritesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final a = station.availability;
    final rack = a?.rackTotCnt ?? station.rackTotCnt ?? 0;
    final bikes = a?.bikeCnt;
    final tone = AppColors.toneFor(bikes);
    final isFavorite = ref.watch(favoritesProvider).asData?.value.contains(station.stationId) ?? false;
    final ago = a == null ? '' : agoLabel(a.updatedAt);

    return Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(station.stationName, style: text.titleMedium)),
              IconButton(
                tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
                onPressed: () => _toggleFavorite(context, ref, isFavorite),
                icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? AppColors.warning.text : null),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                child: Text('No. ${station.stationNo}', style: text.bodySmall),
              ),
              const SizedBox(width: 8),
              StatusPill(bikeCount: bikes),
              if (station.distanceM != null) ...[
                const SizedBox(width: 8),
                Text('${station.distanceM}m', style: text.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: rack > 0 && bikes != null ? (bikes / rack).clamp(0.0, 1.0) : 0,
              color: tone.text,
              backgroundColor: tone.surface(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            a == null ? '실시간 정보를 불러오지 못했어요' : '자전거 ${a.bikeCnt}대 · 거치대 ${a.rackTotCnt}개 · 거치율 ${a.shared}%',
            style: text.bodyMedium,
          ),
          if (ago.isNotEmpty || (a?.stale ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [if (ago.isNotEmpty) '$ago 기준', if (a?.stale ?? false) '최신 정보가 아닐 수 있어요'].join(' · '),
                style: text.bodySmall,
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            height: AppDimens.ctaHeight,
            child: FilledButton(onPressed: onAlert, child: const Text('도착 전 알림 받기')),
          ),
        ],
      ),
    );
  }
}
