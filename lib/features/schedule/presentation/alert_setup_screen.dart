import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../favorites/data/favorite_repository.dart';
import '../../station/domain/station.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule.dart';

class AlertSetupArgs {
  const AlertSetupArgs({required this.station, this.slotType = SlotType.commuteIn, this.existing});

  final Station station;
  final SlotType slotType;

  /// Current schedule for [slotType], used to prefill the form.
  final Schedule? existing;
}

/// [SCR-05] Notification setup modal. Pops with `true` once the schedule is saved.
class AlertSetupScreen extends ConsumerStatefulWidget {
  const AlertSetupScreen({super.key, required this.args});

  final AlertSetupArgs args;

  @override
  ConsumerState<AlertSetupScreen> createState() => _AlertSetupScreenState();
}

class _AlertSetupScreenState extends ConsumerState<AlertSetupScreen> {
  late SlotType _slot;
  int _days = Days.weekdays;
  int _hour = 8;
  int _minute = 30; // always a multiple of 5
  ThresholdMode _mode = ThresholdMode.always;
  int _count = 3;
  bool _saving = false;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _slot = widget.args.slotType;
    final e = widget.args.existing;
    if (e != null) {
      _days = e.notifyDays;
      final parts = e.notifyTime.split(':');
      _hour = int.tryParse(parts[0]) ?? 8;
      _minute = ((int.tryParse(parts[1]) ?? 30) ~/ 5) * 5;
      _mode = e.thresholdMode;
      _count = e.thresholdCount;
    } else if (_slot == SlotType.commuteOut) {
      _hour = 18;
      _minute = 0;
    }
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute ~/ 5);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(scheduleRepositoryProvider).upsert(
            slotType: _slot,
            stationId: widget.args.station.stationId,
            notifyTime: '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
            notifyDays: _days,
            mode: _mode,
            thresholdCount: _count,
          );
      ref.invalidate(homeProvider);
      ref.invalidate(favoritesProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.args.station;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('도착 전 알림'), leading: const CloseButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.pedal_bike, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.stationName, style: text.titleMedium),
                      Text('No. ${station.stationNo}', style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _section('알림 종류'),
          SegmentedButton<SlotType>(
            segments: [for (final s in SlotType.values) ButtonSegment(value: s, label: Text(s.label))],
            selected: {_slot},
            onSelectionChanged: (s) => setState(() => _slot = s.first),
          ),
          _section('요일'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (var i = 0; i < 7; i++) _dayCircle(i)],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              label: const Text('평일 자동 선택'),
              onPressed: () => setState(() => _days = Days.weekdays),
            ),
          ),
          _section('시간 (5분 단위)'),
          SizedBox(
            height: 150,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  pickerTextStyle: TextStyle(fontSize: 20, color: scheme.onSurface),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _hourController,
                      itemExtent: 40,
                      onSelectedItemChanged: (i) => _hour = i,
                      children: [for (var h = 0; h < 24; h++) Center(child: Text('${h.toString().padLeft(2, '0')}시'))],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _minuteController,
                      itemExtent: 40,
                      onSelectedItemChanged: (i) => _minute = i * 5,
                      children: [for (var m = 0; m < 60; m += 5) Center(child: Text('${m.toString().padLeft(2, '0')}분'))],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _section('알림 조건'),
          _modeTile(ThresholdMode.always, '출발 시 바로 알려주기', '대수와 상관없이 매번 알려드려요'),
          _modeTile(ThresholdMode.belowN, '자전거가 적을 때만 알려주기', '설정한 대수 이하일 때만 알려드려요'),
          if (_mode == ThresholdMode.belowN)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    onPressed: _count > 1 ? () => setState(() => _count--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(width: 96, child: Center(child: Text('$_count대 이하', style: text.titleMedium))),
                  IconButton.outlined(
                    onPressed: _count < 20 ? () => setState(() => _count++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: AppDimens.ctaHeight,
            child: FilledButton(
              onPressed: (_saving || _days == 0) ? null : _save,
              child: Text(_saving ? '저장 중...' : '알림 저장'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _dayCircle(int index) {
    final selected = Days.has(_days, index);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => setState(() => _days = Days.toggle(_days, index)),
      child: Container(
        width: AppDimens.minTouch,
        height: AppDimens.minTouch,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(color: selected ? AppColors.primary : scheme.outline),
        ),
        child: Text(
          Days.labels[index],
          style: TextStyle(color: selected ? Colors.white : scheme.onSurface, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _modeTile(ThresholdMode mode, String title, String subtitle) {
    final selected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : Theme.of(context).colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
