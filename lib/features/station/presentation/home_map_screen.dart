import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../../core/location/location_service.dart';
import '../../../core/map/cluster_marker_html.dart';
import '../../../core/map/station_clusterer.dart';
import '../../../core/map/station_marker_html.dart';
import '../../../core/network/api_guard.dart';
import '../../../core/router/app_router.dart';
import '../../device/device_registrar.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../schedule/domain/schedule.dart';
import '../../schedule/presentation/alert_setup_screen.dart';
import '../data/station_repository.dart';
import '../domain/station.dart';
import 'station_sheet.dart';

/// [SCR-03] Full-screen Kakao map with status-coloured count pills (clustered when zoomed out),
/// floating search bar, refresh / my-location FABs and a draggable station sheet.
class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> with SingleTickerProviderStateMixin {
  static const _seoulCityHall = GeoPoint(37.5665, 126.9780);
  static const _initialLevel = 4;

  KakaoMapController? _map;
  GeoPoint _center = _seoulCityHall;
  int _level = _initialLevel;
  List<Station> _visible = const []; // last successfully loaded markers (kept while a new viewport loads)

  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Make sure the backend knows this device (needed by /home, /favorites, /schedules).
      try {
        await ref.read(deviceRegistrarProvider).register();
        ref.invalidate(homeProvider);
      } catch (_) {
        // ApiGuard re-registers on demand, so a failure here is not fatal.
      }
      await _locateMe(silent: true);
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  /// Search radius for the current zoom level (Kakao level 1 = closest).
  static int _radiusFor(int level) => (250 * math.pow(2, level - 3)).clamp(300, 3000).toInt();

  NearbyQuery get _query => NearbyQuery.rounded(_center.lat, _center.lng, _radiusFor(_level));

  void _snack(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _moveTo(GeoPoint p, {int? level}) {
    setState(() {
      _center = p;
      if (level != null) _level = level;
    });
    _map?.setCenter(LatLng(p.lat, p.lng));
    if (level != null) _map?.setLevel(level);
  }

  Future<void> _locateMe({bool silent = false}) async {
    final p = await ref.read(locationServiceProvider).current();
    if (p == null) {
      if (!silent) _snack('위치 권한을 허용하면 내 주변 대여소를 볼 수 있어요');
      return;
    }
    _moveTo(p);
  }

  Future<void> _refresh() async {
    if (_spin.isAnimating) return;
    _spin.repeat();
    try {
      await ref.refresh(nearbyStationsProvider(_query).future);
      ref.invalidate(homeProvider);
    } catch (e) {
      _snack(failureMessage(e));
    } finally {
      _spin
        ..stop()
        ..reset();
    }
  }

  Future<void> _openSearch() async {
    final s = await Navigator.pushNamed<Station>(context, Routes.search);
    if (s == null || !mounted) return;
    ref.read(selectedStationProvider.notifier).state = s;
    if (s.lat != null && s.lng != null) _moveTo(GeoPoint(s.lat!, s.lng!), level: 3);
  }

  Future<void> _openAlertSetup(Station station, {SlotType slot = SlotType.commuteIn, Schedule? existing}) async {
    final saved = await Navigator.pushNamed<bool>(
      context,
      Routes.alertSetup,
      arguments: AlertSetupArgs(station: station, slotType: slot, existing: existing),
    );
    if (saved == true) _snack('알림이 저장되었어요');
  }

  void _onOverlayTap(String id, LatLng latLng) {
    if (id.startsWith('cluster:')) {
      _map?.setCenter(latLng);
      _map?.setLevel((_level - 2).clamp(1, 14));
      return;
    }
    for (final s in _visible) {
      if (s.stationId == id) {
        ref.read(selectedStationProvider.notifier).state = s;
        return;
      }
    }
  }

  List<CustomOverlay> _overlays(List<Station> stations, String? selectedId) {
    final positioned = stations.where((s) => s.lat != null && s.lng != null).toList();
    final groups = clusterByGrid<Station>(positioned, lat: (s) => s.lat!, lng: (s) => s.lng!, level: _level);
    return [
      for (final g in groups)
        if (g.isSingle)
          CustomOverlay(
            customOverlayId: g.members.first.stationId,
            latLng: LatLng(g.lat, g.lng),
            content: StationMarkerHtml.pill(
              bikeCount: g.members.first.bikeCount,
              selected: g.members.first.stationId == selectedId,
            ),
          )
        else
          CustomOverlay(
            customOverlayId: 'cluster:${g.lat.toStringAsFixed(5)},${g.lng.toStringAsFixed(5)}',
            latLng: LatLng(g.lat, g.lng),
            content: ClusterMarkerHtml.bubble(g.members.length),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedStationProvider);
    final nearby = ref.watch(nearbyStationsProvider(_query));
    if (nearby.hasValue) _visible = nearby.requireValue;

    // Markers: loaded stations, plus the selected one if it came from search and is off-screen.
    final markers = [
      ..._visible,
      if (selected != null && !_visible.any((s) => s.stationId == selected.stationId)) selected,
    ];
    // The sheet shows the freshest copy of the selected station.
    final liveSelected = selected == null
        ? null
        : markers.firstWhere((s) => s.stationId == selected.stationId, orElse: () => selected);

    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Stack(
        children: [
          KakaoMap(
            onMapCreated: (controller) => _map = controller,
            center: LatLng(_seoulCityHall.lat, _seoulCityHall.lng),
            currentLevel: _initialLevel,
            customOverlays: _overlays(markers, selected?.stationId),
            onCustomOverlayTap: _onOverlayTap,
            onMapTap: (_) => ref.read(selectedStationProvider.notifier).state = null,
            onCameraIdle: (latLng, zoomLevel) => setState(() {
              _center = GeoPoint(latLng.latitude, latLng.longitude);
              _level = zoomLevel;
            }),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchBar(onSearch: _openSearch, onFavorites: () => Navigator.pushNamed(context, Routes.favorites)),
                    const SizedBox(height: 8),
                    _CommuteChips(onSetup: _openSearch, onEdit: _openAlertSetup),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24 + (liveSelected != null ? height * 0.3 : 0),
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'refresh',
                  tooltip: '새로고침',
                  onPressed: _refresh,
                  child: RotationTransition(turns: _spin, child: const Icon(Icons.refresh)),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'gps',
                  tooltip: '내 위치',
                  onPressed: () => _locateMe(),
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          if (liveSelected != null)
            DraggableScrollableSheet(
              key: ValueKey(liveSelected.stationId),
              initialChildSize: 0.3,
              minChildSize: 0.14,
              maxChildSize: 0.6,
              builder: (context, controller) => StationSheet(
                station: liveSelected,
                scrollController: controller,
                onClose: () => ref.read(selectedStationProvider.notifier).state = null,
                onAlert: () => _openAlertSetup(liveSelected),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onSearch, required this.onFavorites});

  final VoidCallback onSearch;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onSearch,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Icon(Icons.search)),
              Expanded(
                child: Text('대여소 검색 (예: ㅁㅇㅇ, 102)', style: TextStyle(color: Theme.of(context).hintColor)),
              ),
              IconButton(tooltip: '즐겨찾기', onPressed: onFavorites, icon: const Icon(Icons.star_border)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Morning / evening commute summary from GET /api/v1/home.
class _CommuteChips extends ConsumerWidget {
  const _CommuteChips({required this.onSetup, required this.onEdit});

  final VoidCallback onSetup;
  final Future<void> Function(Station station, {SlotType slot, Schedule? existing}) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider).asData?.value;
    if (home == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: [
        _chip(context, SlotType.commuteIn, home.commuteIn),
        _chip(context, SlotType.commuteOut, home.commuteOut),
      ],
    );
  }

  Widget _chip(BuildContext context, SlotType type, CommuteSlot? slot) {
    if (slot == null) {
      return ActionChip(
        avatar: const Icon(Icons.add, size: 18),
        label: Text('${type.label} 알림'),
        onPressed: onSetup,
        backgroundColor: Theme.of(context).colorScheme.surface,
      );
    }
    final s = slot.schedule;
    final count = slot.availability?.bikeCnt;
    return ActionChip(
      label: Text('${type.label} · ${s.stationName} ${count == null ? '-' : '$count대'}'),
      onPressed: () => onEdit(s.station, slot: type, existing: s),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
