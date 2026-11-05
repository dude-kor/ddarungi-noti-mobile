import 'package:ddarungi_noti/core/map/station_clusterer.dart';
import 'package:ddarungi_noti/features/favorites/domain/favorites.dart';
import 'package:ddarungi_noti/features/schedule/domain/schedule.dart';
import 'package:ddarungi_noti/features/station/domain/station.dart';
import 'package:flutter_test/flutter_test.dart';

class _P {
  const _P(this.lat, this.lng);
  final double lat;
  final double lng;
}

void main() {
  group('clusterByGrid', () {
    const items = [_P(37.5011, 127.0011), _P(37.5019, 127.0019), _P(37.6, 127.1)];

    List<ClusterGroup<_P>> run(int level) =>
        clusterByGrid<_P>(items, lat: (p) => p.lat, lng: (p) => p.lng, level: level);

    test('zoomed in: every item stays single', () {
      final groups = run(5);
      expect(groups.length, 3);
      expect(groups.every((g) => g.isSingle), isTrue);
    });

    test('zoomed out: nearby items merge into one cluster with centroid', () {
      final groups = run(6);
      expect(groups.length, 2);
      final merged = groups.firstWhere((g) => !g.isSingle);
      expect(merged.members.length, 2);
      expect(merged.lat, closeTo(37.5015, 1e-9));
      expect(merged.lng, closeTo(127.0015, 1e-9));
    });

    test('very far out: everything nearby collapses further', () {
      expect(run(14).length, lessThanOrEqualTo(2));
    });
  });

  group('Days', () {
    test('describe', () {
      expect(Days.describe(Days.weekdays), '평일');
      expect(Days.describe(Days.everyday), '매일');
      expect(Days.describe(1 | 4 | 16), '월·수·금');
      expect(Days.describe(0), '요일 없음');
    });
    test('toggle and has use the backend bitmask (Mon=1 ... Sun=64)', () {
      expect(Days.has(Days.weekdays, 0), isTrue); // Mon
      expect(Days.has(Days.weekdays, 5), isFalse); // Sat
      expect(Days.toggle(0, 6), 64); // Sun
      expect(Days.toggle(64, 6), 0);
    });
  });

  group('labels', () {
    test('availabilityLabel follows the colour thresholds', () {
      expect(availabilityLabel(null), '정보 없음');
      expect(availabilityLabel(0), '자전거 없음');
      expect(availabilityLabel(2), '2대 · 여유 적음');
      expect(availabilityLabel(7), '7대 · 이용 가능');
    });
    test('agoLabel', () {
      final now = DateTime(2026, 11, 4, 9, 0);
      int ms(Duration ago) => now.subtract(ago).millisecondsSinceEpoch;
      expect(agoLabel(0, now: now), '');
      expect(agoLabel(ms(const Duration(seconds: 20)), now: now), '방금 전');
      expect(agoLabel(ms(const Duration(minutes: 5)), now: now), '5분 전');
      expect(agoLabel(ms(const Duration(hours: 2)), now: now), '2시간 전');
    });
  });

  group('JSON mapping (backend contract)', () {
    test('Station with availability', () {
      final s = Station.fromJson({
        'stationId': 'ST-4',
        'stationNo': '102',
        'stationName': '망원역 1번출구 앞',
        'lat': 37.5558578,
        'lng': 126.910463,
        'rackTotCnt': 15,
        'availability': {
          'bikeCnt': 7,
          'rackTotCnt': 15,
          'shared': 47,
          'status': 'NORMAL',
          'updatedAt': 1762210000000,
          'stale': false,
        },
        'distanceM': 120,
      });
      expect(s.bikeCount, 7);
      expect(s.distanceM, 120);
      expect(s.availability!.stale, isFalse);
    });

    test('Station without availability', () {
      final s = Station.fromJson({
        'stationId': 'ST-9',
        'stationNo': '107',
        'stationName': '서울숲역',
        'availability': null,
      });
      expect(s.bikeCount, isNull);
      expect(s.lat, isNull);
    });

    test('Schedule, HomeSummary and Favorites', () {
      final schedule = {
        'scheduleId': 3,
        'slotType': 'COMMUTE_IN',
        'stationId': 'ST-4',
        'stationNo': '102',
        'stationName': '망원역 1번출구 앞',
        'notifyTime': '08:30',
        'notifyDays': 31,
        'thresholdMode': 'BELOW_N',
        'thresholdCount': 3,
        'active': true,
      };
      final s = Schedule.fromJson(schedule);
      expect(s.tag, '출근 08:30');
      expect(s.detail, '평일 08:30 · 3대 이하');

      final home = HomeSummary.fromJson({
        'commuteIn': {'schedule': schedule, 'availability': null},
        'commuteOut': null,
      });
      expect(home.commuteIn!.schedule.scheduleId, 3);
      expect(home.commuteOut, isNull);

      final fav = FavoritesData.fromJson({
        'count': 1,
        'max': 5,
        'items': [
          {
            'favoriteId': 9,
            'station': {'stationId': 'ST-4', 'stationNo': '102', 'stationName': '망원역 1번출구 앞'},
            'schedule': schedule,
          },
        ],
      });
      expect(fav.contains('ST-4'), isTrue);
      expect(fav.contains('ST-5'), isFalse);
      expect(fav.items.single.schedule!.active, isTrue);
    });
  });
}
