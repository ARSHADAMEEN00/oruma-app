import '../models/home_visit.dart';
import 'api_config.dart';
import 'api_service.dart';

/// HomeVisit service for CRUD operations via the backend API.
class HomeVisitService {
  HomeVisitService._();

  /// Get all home visits from the API.
  static Future<List<HomeVisit>> getAllHomeVisits() async {
    final result = await ApiService.get<List<dynamic>>(
      ApiConfig.homeVisitsEndpoint,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => HomeVisit.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(result.error ?? 'Failed to fetch home visits');
  }

  /// Get a single home visit by ID.
  static Future<HomeVisit> getHomeVisitById(String id) async {
    final result = await ApiService.get<Map<String, dynamic>>(
      '${ApiConfig.homeVisitsEndpoint}/$id',
    );

    if (result.isSuccess && result.data != null) {
      return HomeVisit.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to fetch home visit');
  }

  /// Create a new home visit.
  static Future<HomeVisit> createHomeVisit(HomeVisit homeVisit) async {
    final result = await ApiService.post<Map<String, dynamic>>(
      ApiConfig.homeVisitsEndpoint,
      body: homeVisit.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      return HomeVisit.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to create home visit');
  }

  /// Update an existing home visit.
  static Future<HomeVisit> updateHomeVisit(String id, HomeVisit homeVisit) async {
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.homeVisitsEndpoint}/$id',
      body: homeVisit.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      return HomeVisit.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to update home visit');
  }

  /// Delete a home visit.
  static Future<bool> deleteHomeVisit(String id) async {
    final result = await ApiService.delete(
      '${ApiConfig.homeVisitsEndpoint}/$id',
    );

    if (result.isSuccess) {
      return true;
    }

    throw Exception(result.error ?? 'Failed to delete home visit');
  }
}
