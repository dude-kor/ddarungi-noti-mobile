import 'dart:math' as math;

class ClusterGroup<T> {
  const ClusterGroup(this.lat, this.lng, this.members);

  /// Centroid of the members.
  final double lat;
  final double lng;
  final List<T> members;

  bool get isSingle => members.length == 1;
}

/// Grid clustering for zoomed-out maps. Kakao map levels grow as you zoom OUT (1 = closest);
/// below [clusterFromLevel] every item stays on its own. The grid cell doubles with each level.
List<ClusterGroup<T>> clusterByGrid<T>(
  List<T> items, {
  required double Function(T) lat,
  required double Function(T) lng,
  required int level,
  int clusterFromLevel = 6,
}) {
  if (level < clusterFromLevel) {
    return [for (final i in items) ClusterGroup<T>(lat(i), lng(i), [i])];
  }
  final cell = 0.002 * math.pow(2, level - clusterFromLevel + 1); // ~440 m at level 6
  final buckets = <String, List<T>>{};
  for (final item in items) {
    final key = '${(lat(item) / cell).floor()}:${(lng(item) / cell).floor()}';
    buckets.putIfAbsent(key, () => []).add(item);
  }
  return [
    for (final members in buckets.values)
      ClusterGroup<T>(
        members.map(lat).reduce((a, b) => a + b) / members.length,
        members.map(lng).reduce((a, b) => a + b) / members.length,
        members,
      ),
  ];
}
