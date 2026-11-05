import '../../schedule/domain/schedule.dart';
import '../../station/domain/station.dart';

class Favorite {
  const Favorite({required this.favoriteId, required this.station, this.schedule});

  final int favoriteId;
  final Station station;

  /// The commute alert (if any) the user set up for this station.
  final Schedule? schedule;

  factory Favorite.fromJson(Map<String, dynamic> j) => Favorite(
        favoriteId: (j['favoriteId'] as num).toInt(),
        station: Station.fromJson(j['station'] as Map<String, dynamic>),
        schedule: j['schedule'] == null ? null : Schedule.fromJson(j['schedule'] as Map<String, dynamic>),
      );
}

/// GET /api/v1/favorites
class FavoritesData {
  const FavoritesData({required this.count, required this.max, required this.items});

  final int count;
  final int max;
  final List<Favorite> items;

  bool contains(String stationId) => items.any((f) => f.station.stationId == stationId);

  factory FavoritesData.fromJson(Map<String, dynamic> j) => FavoritesData(
        count: (j['count'] as num).toInt(),
        max: (j['max'] as num).toInt(),
        items: [for (final e in j['items'] as List<dynamic>) Favorite.fromJson(e as Map<String, dynamic>)],
      );
}
