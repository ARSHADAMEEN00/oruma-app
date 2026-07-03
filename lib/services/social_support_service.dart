import '../models/social_support.dart';
import 'api_config.dart';
import 'api_service.dart';

class SocialSupportService {
  SocialSupportService._();

  static Future<List<SocialSupport>> getAllSocialSupports({
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

  static Future<SocialSupport> createSocialSupport(
    SocialSupport support,
  ) async {
    final result = await ApiService.post<Map<String, dynamic>>(
      ApiConfig.v2SocialSupportEndpoint,
      body: support.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      return SocialSupport.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to create social support record');
  }

  static Future<SocialSupport> updateSocialSupport(
    String id,
    SocialSupport support,
  ) async {
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.v2SocialSupportEndpoint}/$id',
      body: support.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      return SocialSupport.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to update social support record');
  }

  static Future<bool> deleteSocialSupport(String id) async {
    final result = await ApiService.delete(
      '${ApiConfig.v2SocialSupportEndpoint}/$id',
    );
    if (result.isSuccess) return true;
    throw Exception(result.error ?? 'Failed to delete social support record');
  }
}
