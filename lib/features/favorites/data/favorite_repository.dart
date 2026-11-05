import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_guard.dart';
import '../../../core/providers.dart';
import '../../device/device_registrar.dart';
import '../domain/favorites.dart';

class FavoriteRepository {
  FavoriteRepository(this._dio, this._guard);

  final Dio _dio;
  final ApiGuard _guard;

  /// GET /api/v1/favorites
  Future<FavoritesData> list() => _guard(() async {
        final r = await _dio.get<Map<String, dynamic>>('/api/v1/favorites');
        return FavoritesData.fromJson(r.data!);
      });

  /// POST /api/v1/favorites/{stationId} (idempotent; 409 FAVORITE_LIMIT_REACHED beyond 5).
  Future<void> add(String stationId) =>
      _guard(() async => _dio.post<void>('/api/v1/favorites/$stationId'));

  /// DELETE /api/v1/favorites/{stationId}
  Future<void> remove(String stationId) =>
      _guard(() async => _dio.delete<void>('/api/v1/favorites/$stationId'));
}

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => FavoriteRepository(ref.watch(dioProvider), ref.watch(apiGuardProvider)),
);

final favoritesProvider = FutureProvider.autoDispose<FavoritesData>(
  (ref) => ref.watch(favoriteRepositoryProvider).list(),
);
