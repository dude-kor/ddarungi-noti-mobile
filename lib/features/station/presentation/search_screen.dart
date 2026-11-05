import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_guard.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/utils/hangul_utils.dart';
import '../../../shared/status_pill.dart';
import '../data/station_repository.dart';
import '../domain/station.dart';

/// [SCR-04] Debounced (200ms) station search. The backend matches names, numbers and chosung
/// ('ㅁㅇㅇ' -> 망원역). Pops with the tapped [Station].
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _useQuery(String q) {
    _controller.value = TextEditingValue(text: q, selection: TextSelection.collapsed(offset: q.length));
    _debounce?.cancel();
    setState(() => _query = q);
  }

  Future<void> _pick(Station station) async {
    await ref.read(appPrefsProvider).addRecentSearch(station.stationName);
    if (mounted) Navigator.pop(context, station);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '대여소 이름·번호 (예: ㅁㅇㅇ, 102)',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.close), onPressed: () => _useQuery('')),
        ],
      ),
      body: _query.isEmpty ? _recents() : _results(),
    );
  }

  Widget _recents() {
    final recents = ref.watch(appPrefsProvider).recentSearches;
    if (recents.isEmpty) {
      return const _EmptyState(icon: Icons.search, message: '대여소 이름이나 번호,\n초성으로 검색해 보세요');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 검색', style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () async {
                await ref.read(appPrefsProvider).clearRecentSearches();
                if (mounted) setState(() {});
              },
              child: const Text('전체 삭제'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [for (final r in recents) ActionChip(label: Text(r), onPressed: () => _useQuery(r))],
        ),
      ],
    );
  }

  Widget _results() {
    // Recent searches that match what is being typed (chosung-aware) double as suggestions.
    final suggestions = ref
        .watch(appPrefsProvider)
        .recentSearches
        .where((r) => r != _query && HangulUtils.matches(r, _query))
        .toList();

    final results = ref.watch(searchResultsProvider(_query));
    return Column(
      children: [
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final s in suggestions) ActionChip(label: Text(s), onPressed: () => _useQuery(s)),
                ],
              ),
            ),
          ),
        Expanded(
          child: results.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _EmptyState(icon: Icons.cloud_off, message: failureMessage(e)),
            data: (list) => list.isEmpty
                ? const _EmptyState(icon: Icons.search_off, message: '검색 결과가 없어요')
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = list[i];
                      return ListTile(
                        minVerticalPadding: 12,
                        title: Text(s.stationName),
                        subtitle: Text('No. ${s.stationNo}'),
                        trailing: StatusPill(bikeCount: s.bikeCount),
                        onTap: () => _pick(s),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
