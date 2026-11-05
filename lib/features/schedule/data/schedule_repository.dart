import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_guard.dart';
import '../../../core/providers.dart';
import '../../device/device_registrar.dart';
import '../domain/schedule.dart';

class ScheduleRepository {
  ScheduleRepository(this._dio, this._guard);

  final Dio _dio;
  final ApiGuard _guard;

  /// GET /api/v1/home – the morning / evening commute slots with live availability.
  Future<HomeSummary> home() => _guard(() async {
        final r = await _dio.get<Map<String, dynamic>>('/api/v1/home');
        return HomeSummary.fromJson(r.data!);
      });

  /// POST /api/v1/schedules – one schedule per (device, slot); posting again replaces it.
  Future<Schedule> upsert({
    required SlotType slotType,
    required String stationId,
    required String notifyTime, // "HH:mm", 5-minute steps
    required int notifyDays,
    required ThresholdMode mode,
    required int thresholdCount,
  }) =>
      _guard(() async {
        final r = await _dio.post<Map<String, dynamic>>('/api/v1/schedules', data: {
          'slotType': slotType.api,
          'stationId': stationId,
          'notifyTime': notifyTime,
          'notifyDays': notifyDays,
          'thresholdMode': mode.api,
          'thresholdCount': mode == ThresholdMode.belowN ? thresholdCount : null,
        });
        return Schedule.fromJson(r.data!);
      });

  /// PATCH /api/v1/schedules/{id}/toggle
  Future<Schedule> toggle(int scheduleId) => _guard(() async {
        final r = await _dio.patch<Map<String, dynamic>>('/api/v1/schedules/$scheduleId/toggle');
        return Schedule.fromJson(r.data!);
      });
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(ref.watch(dioProvider), ref.watch(apiGuardProvider)),
);

final homeProvider = FutureProvider.autoDispose<HomeSummary>(
  (ref) => ref.watch(scheduleRepositoryProvider).home(),
);
