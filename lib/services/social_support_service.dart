import '../models/social_support.dart';
import 'api_config.dart';
import 'api_service.dart';
import 'app_cache.dart';

class SocialSupportService {
  SocialSupportService._();

  static const _prefix = 'social:';
  static const _keyAll = 'social:all';
  static const _ttl = Duration(minutes: 5);

  /// Get social supports. The unfiltered list (no patientId, dates, or search)
  /// is cached for [_ttl]. Filtered calls are always fetched live so
  /// patient-specific views stay accurate.
  static Future<List<SocialSupport>> getAllSocialSupports({
    String? patientId,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
  }) async {
    final isFiltered =
        (patientId?.trim().isNotEmpty ?? false) ||
        fromDate != null ||
        toDate != null ||
        (search?.trim().isNotEmpty ?? false);

    if (isFiltered) {
      return _fetchSocialSupports(
        patientId: patientId,
        fromDate: fromDate,
        toDate: toDate,
        search: search,
      );
    }

    return AppCache.get<List<SocialSupport>>(
      _keyAll,
      ttl: _ttl,
      loader: () => _fetchSocialSupports(),
    );
  }

  static Future<List<SocialSupport>> _fetchSocialSupports({
    String? patientId,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
  }) async {
    final query = <String, String>{};
    if (patientId?.trim().isNotEmpty == true) query['patientId'] = patientId!;
    if (fromDate != null) query['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) query['toDate'] = toDate.toIso8601String();
    if (search?.trim().isNotEmpty == true) query['search'] = search!.trim();

    final uri = Uri.parse(
      ApiConfig.v2SocialSupportEndpoint,
    ).replace(queryParameters: query.isEmpty ? null : query);

    final result = await ApiService.get<List<dynamic>>(uri.toString());
    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => SocialSupport.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(result.error ?? 'Failed to fetch social support records');
  }

  /// Create a social support record and invalidate the cache.
  static Future<SocialSupport> createSocialSupport(
    SocialSupport support,
  ) async {
    final result = await ApiService.post<Map<String, dynamic>>(
      ApiConfig.v2SocialSupportEndpoint,
      body: support.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      AppCache.invalidatePrefix(_prefix);
      return SocialSupport.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to create social support record');
  }

  /// Update a social support record and invalidate the cache.
  static Future<SocialSupport> updateSocialSupport(
    String id,
    SocialSupport support,
  ) async {
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.v2SocialSupportEndpoint}/$id',
      body: support.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      AppCache.invalidatePrefix(_prefix);
      return SocialSupport.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to update social support record');
  }

  /// Delete a social support record and invalidate the cache.
  static Future<bool> deleteSocialSupport(String id) async {
    final result = await ApiService.delete(
      '${ApiConfig.v2SocialSupportEndpoint}/$id',
    );
    if (result.isSuccess) {
      AppCache.invalidatePrefix(_prefix);
      return true;
    }
    throw Exception(result.error ?? 'Failed to delete social support record');
  }
}
