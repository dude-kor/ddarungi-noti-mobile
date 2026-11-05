import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_guard.dart';
import '../../../core/providers.dart';
import '../../device/device_registrar.dart';
import '../domain/station.dart';

class StationRepository {
  StationRepository(this._dio, this._guard);

  final Dio _dio;
  final ApiGuard _guard;

  /// GET /api/v1/stations/search?q= (the backend matches names, numbers and chosung such as 'ㅁㅇㅇ').
  Future<List<Station>> search(String query) => _guard(() async {
        final r = await _dio.get<List<dynamic>>('/api/v1/stations/search', queryParameters: {'q': query});
        return _parse(r.data);
      });

  /// GET /api/v1/stations/nearby – nearest first, with live availability, for the map markers.
  Future<List<Station>> nearby({
    required double lat,
    required double lng,
    required int radius,
    int limit = 100,
  }) =>
      _guard(() async {
        final r = await _dio.get<List<dynamic>>('/api/v1/stations/nearby',
            queryParameters: {'lat': lat, 'lng': lng, 'radius': radius, 'limit': limit});
        return _parse(r.data);
      });

  static List<Station> _parse(List<dynamic>? data) =>
      [for (final e in data ?? const []) Station.fromJson(e as Map<String, dynamic>)];
}

final stationRepositoryProvider = Provider<StationRepository>(
  (ref) => StationRepository(ref.watch(dioProvider), ref.watch(apiGuardProvider)),
);

/// Map viewport query. Coordinates are rounded (~110 m) so small pans reuse the cached result.
class NearbyQuery {
  const NearbyQuery(this.lat, this.lng, this.radius);

  factory NearbyQuery.rounded(double lat, double lng, int radius) =>
      NearbyQuery((lat * 1000).round() / 1000, (lng * 1000).round() / 1000, radius);

  final double lat;
  final double lng;
  final int radius;

  @override
  bool operator ==(Object other) =>
      other is NearbyQuery && other.lat == lat && other.lng == lng && other.radius == radius;

  @override
  int get hashCode => Object.hash(lat, lng, radius);
}

final nearbyStationsProvider = FutureProvider.autoDispose.family<List<Station>, NearbyQuery>(
  (ref, q) => ref.watch(stationRepositoryProvider).nearby(lat: q.lat, lng: q.lng, radius: q.radius),
);

final searchResultsProvider = FutureProvider.autoDispose.family<List<Station>, String>(
  (ref, q) => ref.watch(stationRepositoryProvider).search(q),
);

/// Station highlighted on the map (drives the bottom sheet).
final selectedStationProvider = StateProvider<Station?>((ref) => null);
