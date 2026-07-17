import '../models/app_notification.dart';
import 'api_config.dart';
import 'api_service.dart';
import 'app_cache.dart';

class NotificationService {
  NotificationService._();

  static const _prefix = 'notifications:';
  static const _keyActive = 'notifications:active';
  static const _ttlActive = Duration(minutes: 2);

  static Future<List<AppNotification>> getActiveNotifications({
    bool refresh = false,
  }) async {
    if (refresh) {
      AppCache.invalidatePrefix(_prefix);
    }

    return AppCache.get<List<AppNotification>>(
      _keyActive,
      ttl: _ttlActive,
      loader: _fetchActiveNotifications,
    );
  }

  static Future<List<AppNotification>> _fetchActiveNotifications() async {
    final result = await ApiService.get<dynamic>(
      ApiConfig.notificationsEndpoint,
    );
    if (result.isSuccess && result.data != null) {
      final data = result.data;
      final rawList = data is Map
          ? data['notifications']
          : data is List
          ? data
          : <dynamic>[];

      if (rawList is List) {
        return rawList
            .whereType<Map>()
            .map(
              (json) =>
                  AppNotification.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }
    }

    throw Exception(result.error ?? 'Failed to fetch notifications');
  }

  static Future<AppNotification> markRead(String id) async {
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.notificationsEndpoint}/$id/read',
      body: {},
    );
    if (result.isSuccess && result.data != null) {
      AppCache.invalidatePrefix(_prefix);
      return AppNotification.fromJson(result.data!);
    }
    throw Exception(result.error ?? 'Failed to mark notification as read');
  }
}
