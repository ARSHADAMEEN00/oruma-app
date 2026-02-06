import '../models/equipment_supply.dart';
import 'api_config.dart';
import 'api_service.dart';

class EquipmentSupplyService {
  EquipmentSupplyService._();

  /// Get all supplies
  static Future<List<EquipmentSupply>> getAllSupplies() async {
    final result = await ApiService.get<List<dynamic>>(
      ApiConfig.equipmentSuppliesEndpoint,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => EquipmentSupply.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception(result.error ?? 'Failed to fetch supplies');
  }

  /// Get active supplies (updates UI)
  static Future<List<EquipmentSupply>> getActiveSupplies() async {
    final result = await ApiService.get<List<dynamic>>(
      '${ApiConfig.equipmentSuppliesEndpoint}/active',
    );

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => EquipmentSupply.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception(result.error ?? 'Failed to fetch active supplies');
  }

  /// Get supply by ID
  static Future<EquipmentSupply> getById(String id) async {
    final result = await ApiService.get<Map<String, dynamic>>(
      '${ApiConfig.equipmentSuppliesEndpoint}/$id',
    );

    if (result.isSuccess && result.data != null) {
      return EquipmentSupply.fromJson(result.data!);
    }
    throw Exception(result.error ?? 'Failed to fetch supply');
  }

  /// Create new supply (Assign equipment to patient)
  static Future<EquipmentSupply> createSupply(EquipmentSupply supply) async {
    final result = await ApiService.post<Map<String, dynamic>>(
      ApiConfig.equipmentSuppliesEndpoint,
      body: supply.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      return EquipmentSupply.fromJson(result.data!);
    }
    throw Exception(result.error ?? 'Failed to create supply');
  }

  /// Update supply (e.g. mark returned)
  static Future<EquipmentSupply> updateSupply(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.equipmentSuppliesEndpoint}/$id',
      body: updates,
    );

    if (result.isSuccess && result.data != null) {
      return EquipmentSupply.fromJson(result.data!);
    }
    throw Exception(result.error ?? 'Failed to update supply');
  }

  /// Mark supply as returned using specific endpoint
  static Future<EquipmentSupply> returnSupply(
    String id, {
    DateTime? date,
    String? note,
  }) async {
    final updates = {
      if (date != null) 'actualReturnDate': date.toIso8601String(),
      if (note != null && note.isNotEmpty) 'returnNote': note,
    };
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.equipmentSuppliesEndpoint}/$id/return',
      body: updates,
    );

    if (result.isSuccess && result.data != null) {
      return EquipmentSupply.fromJson(result.data!);
    }
    throw Exception(result.error ?? 'Failed to mark supply as returned');
  }

  /// Delete supply
  static Future<bool> deleteSupply(String id) async {
    final result = await ApiService.delete(
      '${ApiConfig.equipmentSuppliesEndpoint}/$id',
    );

    if (result.isSuccess) {
      return true;
    }
    throw Exception(result.error ?? 'Failed to delete supply');
  }
}
