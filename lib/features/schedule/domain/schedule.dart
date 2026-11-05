import '../../station/domain/station.dart';

enum SlotType {
  commuteIn('COMMUTE_IN', '출근'),
  commuteOut('COMMUTE_OUT', '퇴근');

  const SlotType(this.api, this.label);

  final String api;
  final String label;

  static SlotType fromApi(String v) => values.firstWhere((e) => e.api == v);
}

enum ThresholdMode {
  always('ALWAYS'),
  belowN('BELOW_N');

  const ThresholdMode(this.api);

  final String api;

  static ThresholdMode fromApi(String v) => values.firstWhere((e) => e.api == v);
}

/// notify_days bitmask: Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64 (index 0 = Monday).
abstract final class Days {
  static const int weekdays = 31;
  static const int everyday = 127;
  static const List<String> labels = ['월', '화', '수', '목', '금', '토', '일'];

  static bool has(int mask, int index) => (mask & (1 << index)) != 0;
  static int toggle(int mask, int index) => mask ^ (1 << index);

  static String describe(int mask) {
    if (mask == weekdays) return '평일';
    if (mask == everyday) return '매일';
    final picked = [for (var i = 0; i < 7; i++) if (has(mask, i)) labels[i]];
    return picked.isEmpty ? '요일 없음' : picked.join('·');
  }
}

class Schedule {
  const Schedule({
    required this.scheduleId,
    required this.slotType,
    required this.stationId,
    required this.stationNo,
    required this.stationName,
    required this.notifyTime,
    required this.notifyDays,
    required this.thresholdMode,
    required this.thresholdCount,
    required this.active,
  });

  final int scheduleId;
  final SlotType slotType;
  final String stationId;
  final String stationNo;
  final String stationName;

  /// "HH:mm".
  final String notifyTime;
  final int notifyDays;
  final ThresholdMode thresholdMode;
  final int thresholdCount;
  final bool active;

  /// "출근 08:30" style tag for cards and chips.
  String get tag => '${slotType.label} $notifyTime';

  /// "평일 08:30 · 3대 이하" / "평일 08:30 · 출발 시 바로".
  String get detail =>
      '${Days.describe(notifyDays)} $notifyTime · ${thresholdMode == ThresholdMode.belowN ? '$thresholdCount대 이하' : '출발 시 바로'}';

  Station get station => Station(stationId: stationId, stationNo: stationNo, stationName: stationName);

  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
        scheduleId: (j['scheduleId'] as num).toInt(),
        slotType: SlotType.fromApi(j['slotType'] as String),
        stationId: j['stationId'] as String,
        stationNo: j['stationNo'] as String,
        stationName: j['stationName'] as String,
        notifyTime: j['notifyTime'] as String,
        notifyDays: (j['notifyDays'] as num).toInt(),
        thresholdMode: ThresholdMode.fromApi(j['thresholdMode'] as String),
        thresholdCount: (j['thresholdCount'] as num).toInt(),
        active: j['active'] as bool,
      );
}

class CommuteSlot {
  const CommuteSlot({required this.schedule, this.availability});

  final Schedule schedule;
  final Availability? availability;

  factory CommuteSlot.fromJson(Map<String, dynamic> j) => CommuteSlot(
        schedule: Schedule.fromJson(j['schedule'] as Map<String, dynamic>),
        availability: j['availability'] == null
            ? null
            : Availability.fromJson(j['availability'] as Map<String, dynamic>),
      );
}

/// GET /api/v1/home
class HomeSummary {
  const HomeSummary({this.commuteIn, this.commuteOut});

  final CommuteSlot? commuteIn;
  final CommuteSlot? commuteOut;

  factory HomeSummary.fromJson(Map<String, dynamic> j) => HomeSummary(
        commuteIn: j['commuteIn'] == null ? null : CommuteSlot.fromJson(j['commuteIn'] as Map<String, dynamic>),
        commuteOut: j['commuteOut'] == null ? null : CommuteSlot.fromJson(j['commuteOut'] as Map<String, dynamic>),
      );
}
