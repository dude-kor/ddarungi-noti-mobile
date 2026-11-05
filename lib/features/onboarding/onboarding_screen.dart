import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/storage/app_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// [SCR-01] Welcome + terms checklist with a bottom-fixed 52px CTA.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _service = false;
  bool _privacy = false;
  bool _marketing = false;

  bool get _all => _service && _privacy && _marketing;
  bool get _canStart => _service && _privacy;

  void _setAll(bool v) => setState(() => _service = _privacy = _marketing = v);

  Future<void> _start() async {
    await ref.read(appPrefsProvider).completeOnboarding(marketingOptIn: _marketing);
    if (mounted) Navigator.pushReplacementNamed(context, Routes.permission);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Icon(Icons.pedal_bike, size: 72, color: AppColors.primary),
              const SizedBox(height: 24),
              Text('따릉이 알리미', style: text.headlineSmall),
              const SizedBox(height: 8),
              Text('출퇴근 전에 내 대여소의 따릉이 대수를\n알림으로 미리 알려드려요.', style: text.bodyLarge),
              const Spacer(),
              _TermTile(label: '전체 동의', value: _all, onChanged: _setAll, bold: true),
              const Divider(height: 1),
              _TermTile(
                  label: '[필수] 서비스 이용약관', value: _service, onChanged: (v) => setState(() => _service = v)),
              _TermTile(
                  label: '[필수] 개인정보 처리방침', value: _privacy, onChanged: (v) => setState(() => _privacy = v)),
              _TermTile(
                  label: '[선택] 알림·이벤트 정보 수신', value: _marketing, onChanged: (v) => setState(() => _marketing = v)),
              const SizedBox(height: 16),
              SizedBox(
                height: AppDimens.ctaHeight,
                width: double.infinity,
                child: FilledButton(onPressed: _canStart ? _start : null, child: const Text('시작하기')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermTile extends StatelessWidget {
  const _TermTile({required this.label, required this.value, required this.onChanged, this.bold = false});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppDimens.minTouch),
        child: Row(
          children: [
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false), activeColor: AppColors.primary),
            Expanded(
              child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
            ),
          ],
        ),
      ),
    );
  }
}
