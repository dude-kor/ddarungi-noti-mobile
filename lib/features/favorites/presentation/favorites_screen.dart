import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_guard.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/status_pill.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../schedule/presentation/alert_setup_screen.dart';
import '../../schedule/domain/schedule.dart';
import '../data/favorite_repository.dart';
import '../domain/favorites.dart';

/// [SCR-06] Favourites: quota banner, availability cards with schedule tag and on/off switch,
/// swipe-to-delete, long-press reordering (order is persisted locally).
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  /// Stations swiped away whose DELETE is still in flight (a Dismissible must leave the tree at once).
  final Set<String> _removed = {};

  List<Favorite> _ordered(List<Favorite> items) {
    final order = ref.read(appPrefsProvider).favoriteOrder;
    int rank(Favorite f) {
      final i = order.indexOf(f.station.stationId);
      return i < 0 ? order.length : i;
    }

    final visible = items.where((f) => !_removed.contains(f.station.stationId)).toList();
    visible.sort((a, b) => rank(a).compareTo(rank(b))); // stable: unknown stations keep server order
    return visible;
  }

  Future<void> _reorder(List<Favorite> items, int oldIndex, int newIndex) async {
    final ids = [for (final f in items) f.station.stationId];
    if (newIndex > oldIndex) newIndex -= 1;
    ids.insert(newIndex, ids.removeAt(oldIndex));
    await ref.read(appPrefsProvider).setFavoriteOrder(ids);
    if (mounted) setState(() {});
  }

  Future<void> _delete(Favorite f) async {
    final id = f.station.stationId;
    setState(() => _removed.add(id));
    try {
      await ref.read(favoriteRepositoryProvider).remove(id);
      ref.invalidate(favoritesProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _removed.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(e))));
    }
  }

  Future<void> _toggle(Schedule schedule) async {
    try {
      await ref.read(scheduleRepositoryProvider).toggle(schedule.scheduleId);
      ref.invalidate(favoritesProvider);
      ref.invalidate(homeProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('즐겨찾기')),
      body: favorites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(failureMessage(e)),
              TextButton(onPressed: () => ref.invalidate(favoritesProvider), child: const Text('다시 시도')),
            ],
          ),
        ),
        data: (data) {
          final items = _ordered(data.items);
          return Column(
            children: [
              _QuotaBanner(count: items.length, max: data.max),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('즐겨찾는 대여소가 없어요\n지도에서 대여소를 눌러 추가해 보세요', textAlign: TextAlign.center))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        buildDefaultDragHandles: false,
                        itemCount: items.length,
                        onReorder: (o, n) => _reorder(items, o, n),
                        itemBuilder: (context, i) {
                          final f = items[i];
                          return Padding(
                            key: ValueKey(f.station.stationId),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: ValueKey('dismiss-${f.station.stationId}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.text,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) => _delete(f),
                              // Long press starts the drag (reordering); a plain tap opens the alert setup.
                              child: ReorderableDelayedDragStartListener(
                                index: i,
                                child: _FavoriteCard(
                                  favorite: f,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    Routes.alertSetup,
                                    arguments: AlertSetupArgs(
                                      station: f.station,
                                      slotType: f.schedule?.slotType ?? SlotType.commuteIn,
                                      existing: f.schedule,
                                    ),
                                  ),
                                  onToggle: f.schedule == null ? null : () => _toggle(f.schedule!),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuotaBanner extends StatelessWidget {
  const _QuotaBanner({required this.count, required this.max});

  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final full = count >= max;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: full ? AppColors.warning.surface(Theme.of(context).brightness) : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('$count / $max개', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Expanded(child: Text(full ? '더 추가하려면 하나를 삭제해 주세요' : '길게 눌러 순서를 바꿀 수 있어요')),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.favorite, required this.onTap, required this.onToggle});

  final Favorite favorite;
  final VoidCallback onTap;

  /// Null when the station has no alert yet (the switch is then disabled).
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final s = favorite.station;
    final schedule = favorite.schedule;
    final text = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.stationName, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text('No. ${s.stationNo}', style: text.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(bikeCount: s.bikeCount),
                        if (schedule != null) Text(schedule.tag, style: text.bodySmall),
                        if (s.availability?.stale ?? false) Text('최신 정보가 아닐 수 있어요', style: text.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: schedule?.active ?? false,
                onChanged: onToggle == null ? null : (_) => onToggle!(),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
