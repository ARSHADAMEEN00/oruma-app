import '../models/medicine_supply.dart';
import 'api_config.dart';
import 'api_service.dart';
import 'app_cache.dart';

/// MedicineSupply service for CRUD operations via the backend API.
class MedicineSupplyService {
  MedicineSupplyService._();

  static const _prefix = 'med_supplies:';
  static const _keyAll = 'med_supplies:all';
  static const _ttl = Duration(minutes: 5);

  /// Get all medicine supplies from the API. Cached for [_ttl].
  static Future<List<MedicineSupply>> getAllMedicineSupplies() async {
    return AppCache.get<List<MedicineSupply>>(
      _keyAll,
      ttl: _ttl,
      loader: _fetchAllMedicineSupplies,
    );
  }

  static Future<List<MedicineSupply>> _fetchAllMedicineSupplies() async {
    final result = await ApiService.get<List<dynamic>>(
      ApiConfig.v2MedicineSuppliesEndpoint,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => MedicineSupply.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(result.error ?? 'Failed to fetch medicine supplies');
  }

  /// Get a single medicine supply by ID (not cached).
  static Future<MedicineSupply> getMedicineSupplyById(String id) async {
    final result = await ApiService.get<Map<String, dynamic>>(
      '${ApiConfig.v2MedicineSuppliesEndpoint}/$id',
    );

    if (result.isSuccess && result.data != null) {
      return MedicineSupply.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to fetch medicine supply');
  }

  /// Create a new medicine supply and invalidate the cache.
  static Future<MedicineSupply> createMedicineSupply(
    MedicineSupply supply,
  ) async {
    final result = await ApiService.post<Map<String, dynamic>>(
      ApiConfig.v2MedicineSuppliesEndpoint,
      body: supply.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      AppCache.invalidatePrefix(_prefix);
      AppCache.invalidatePrefix('medicines:');
      return MedicineSupply.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to create medicine supply');
  }

  /// Update an existing medicine supply and invalidate the cache.
  static Future<MedicineSupply> updateMedicineSupply(
    String id,
    MedicineSupply supply,
  ) async {
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.v2MedicineSuppliesEndpoint}/$id',
      body: supply.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      AppCache.invalidatePrefix(_prefix);
      AppCache.invalidatePrefix('medicines:');
      return MedicineSupply.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to update medicine supply');
  }

  /// Delete a medicine supply and invalidate the cache.
  static Future<bool> deleteMedicineSupply(String id) async {
    final result = await ApiService.delete(
      '${ApiConfig.v2MedicineSuppliesEndpoint}/$id',
    );

    if (result.isSuccess) {
      AppCache.invalidatePrefix(_prefix);
      AppCache.invalidatePrefix('medicines:');
      return true;
    }

    throw Exception(result.error ?? 'Failed to delete medicine supply');
  }
}
