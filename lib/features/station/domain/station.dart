/// Live availability as served by the backend (`StationAvailability`).
class Availability {
  const Availability({
    required this.bikeCnt,
    required this.rackTotCnt,
    required this.shared,
    required this.status,
    required this.updatedAt,
    required this.stale,
  });

  final int bikeCnt;
  final int rackTotCnt;

  /// 거치율 (%).
  final int shared;
  final String status;

  /// Epoch milliseconds of the Seoul API snapshot.
  final int updatedAt;

  /// Served from the fallback snapshot while the Seoul API is down.
  final bool stale;

  factory Availability.fromJson(Map<String, dynamic> j) => Availability(
        bikeCnt: (j['bikeCnt'] as num).toInt(),
        rackTotCnt: (j['rackTotCnt'] as num).toInt(),
        shared: (j['shared'] as num).toInt(),
        status: (j['status'] as String?) ?? 'NORMAL',
        updatedAt: (j['updatedAt'] as num?)?.toInt() ?? 0,
        stale: (j['stale'] as bool?) ?? false,
      );
}

class Station {
  const Station({
    required this.stationId,
    required this.stationNo,
    required this.stationName,
    this.lat,
    this.lng,
    this.rackTotCnt,
    this.availability,
    this.distanceM,
  });

  final String stationId;
  final String stationNo;
  final String stationName;
  final double? lat;
  final double? lng;
  final int? rackTotCnt;
  final Availability? availability;
  final int? distanceM;

  int? get bikeCount => availability?.bikeCnt;

  factory Station.fromJson(Map<String, dynamic> j) => Station(
        stationId: j['stationId'] as String,
        stationNo: j['stationNo'] as String,
        stationName: j['stationName'] as String,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        rackTotCnt: (j['rackTotCnt'] as num?)?.toInt(),
        availability: j['availability'] == null
            ? null
            : Availability.fromJson(j['availability'] as Map<String, dynamic>),
        distanceM: (j['distanceM'] as num?)?.toInt(),
      );
}

/// Status wording shown next to the colour pill.
String availabilityLabel(int? bikeCount) {
  if (bikeCount == null || bikeCount < 0) return '정보 없음';
  if (bikeCount == 0) return '자전거 없음';
  if (bikeCount <= 3) return '$bikeCount대 · 여유 적음';
  return '$bikeCount대 · 이용 가능';
}

/// "방금 전", "5분 전", "2시간 전" for an epoch-millisecond timestamp ('' when unknown).
String agoLabel(int epochMs, {DateTime? now}) {
  if (epochMs <= 0) return '';
  final diff = (now ?? DateTime.now()).difference(DateTime.fromMillisecondsSinceEpoch(epochMs));
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  return '${diff.inHours}시간 전';
}
