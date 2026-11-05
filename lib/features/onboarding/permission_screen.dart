import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/location_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../device/device_registrar.dart';

/// [SCR-02] Pre-prompt explaining why location and push are needed, shown before the OS dialogs.
class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _busy = false;

  Future<void> _requestNotifications() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {
      // Permission prompts must never block onboarding.
    }
  }

  Future<void> _continue({required bool ask}) async {
    setState(() => _busy = true);
    if (ask) {
      await ref.read(locationServiceProvider).ensurePermission();
      await _requestNotifications();
    }
    try {
      await ref.read(deviceRegistrarProvider).register();
    } catch (_) {
      // The home screen retries (ApiGuard re-registers on UNKNOWN_DEVICE).
    }
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('원활한 이용을 위해\n권한을 허용해 주세요', style: text.headlineSmall),
              const SizedBox(height: 32),
              const _PermissionCard(
                icon: Icons.my_location,
                title: '위치 (필수)',
                body: '지도에서 내 주변 대여소를 보여드리기 위해 사용해요.',
              ),
              const SizedBox(height: 12),
              const _PermissionCard(
                icon: Icons.notifications_active,
                title: '알림',
                body: '출발 직전에 대여소의 남은 자전거 수를 알려드려요.',
              ),
              const Spacer(),
              SizedBox(
                height: AppDimens.ctaHeight,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : () => _continue(ask: true),
                  child: const Text('허용하고 계속'),
                ),
              ),
              SizedBox(
                height: AppDimens.ctaHeight,
                width: double.infinity,
                child: TextButton(
                  onPressed: _busy ? null : () => _continue(ask: false),
                  child: const Text('나중에 하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
