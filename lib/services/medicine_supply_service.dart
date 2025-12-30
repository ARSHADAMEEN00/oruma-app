import '../models/medicine_supply.dart';
import 'api_config.dart';
import 'api_service.dart';

/// MedicineSupply service for CRUD operations via the backend API.
class MedicineSupplyService {
  MedicineSupplyService._();

  /// Get all medicine supplies from the API.
  static Future<List<MedicineSupply>> getAllMedicineSupplies() async {
    final result = await ApiService.get<List<dynamic>>(
      ApiConfig.medicineSuppliesEndpoint,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => MedicineSupply.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(result.error ?? 'Failed to fetch medicine supplies');
  }

  /// Get a single medicine supply by ID.
  static Future<MedicineSupply> getMedicineSupplyById(String id) async {
    final result = await ApiService.get<Map<String, dynamic>>(
      '${ApiConfig.medicineSuppliesEndpoint}/$id',
    );

    if (result.isSuccess && result.data != null) {
      return MedicineSupply.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to fetch medicine supply');
  }

  /// Create a new medicine supply.
  static Future<MedicineSupply> createMedicineSupply(MedicineSupply supply) async {
    final result = await ApiService.post<Map<String, dynamic>>(
      ApiConfig.medicineSuppliesEndpoint,
      body: supply.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      return MedicineSupply.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to create medicine supply');
  }

  /// Update an existing medicine supply.
  static Future<MedicineSupply> updateMedicineSupply(String id, MedicineSupply supply) async {
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.medicineSuppliesEndpoint}/$id',
      body: supply.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      return MedicineSupply.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to update medicine supply');
  }

  /// Delete a medicine supply.
  static Future<bool> deleteMedicineSupply(String id) async {
    final result = await ApiService.delete(
      '${ApiConfig.medicineSuppliesEndpoint}/$id',
    );

    if (result.isSuccess) {
      return true;
    }

    throw Exception(result.error ?? 'Failed to delete medicine supply');
  }
}
