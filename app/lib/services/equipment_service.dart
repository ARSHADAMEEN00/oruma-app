import '../models/equipment.dart';
import 'api_config.dart';
import 'api_service.dart';

/// Response from bulk equipment creation
class CreateEquipmentResponse {
  final String message;
  final int count;
  final List<Equipment> equipment;

  CreateEquipmentResponse({
    required this.message,
    required this.count,
    required this.equipment,
  });

  factory CreateEquipmentResponse.fromJson(Map<String, dynamic> json) {
    final equipmentList =
        (json['equipment'] as List<dynamic>?)
            ?.map((e) => Equipment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return CreateEquipmentResponse(
      message: json['message']?.toString() ?? '',
      count: json['count'] as int? ?? equipmentList.length,
      equipment: equipmentList,
    );
  }
}

/// Equipment service for CRUD operations via the backend API.
class EquipmentService {
  EquipmentService._();

  /// Get all equipment from the API.
  static Future<List<Equipment>> getAllEquipment({String? status}) async {
    String url = ApiConfig.equipmentEndpoint;
    if (status != null) {
      url += '?status=$status';
    }

    final result = await ApiService.get<List<dynamic>>(url);

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => Equipment.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(result.error ?? 'Failed to fetch equipment');
  }

  /// Get only available equipment.
  static Future<List<Equipment>> getAvailableEquipment() async {
    return getAllEquipment(status: 'available');
  }

  /// Get a single equipment by ID.
  static Future<Equipment> getEquipmentById(String id) async {
    final result = await ApiService.get<Map<String, dynamic>>(
      '${ApiConfig.equipmentEndpoint}/$id',
    );

    if (result.isSuccess && result.data != null) {
      return Equipment.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to fetch equipment');
  }

  /// Create new equipment (creates multiple if quantity > 1).
  /// Returns a response with all created equipment items.
  static Future<CreateEquipmentResponse> createEquipment({
    required String name,
    required int quantity,
    required String purchasedFrom,
    required String place,
    required String phone,
    String? serialNo,
  }) async {
    final result = await ApiService.post<Map<String, dynamic>>(
      ApiConfig.equipmentEndpoint,
      body: {
        'name': name,
        'quantity': quantity,
        'purchasedFrom': purchasedFrom,
        'place': place,
        'phone': phone,
        if (serialNo != null) 'serialNo': serialNo,
      },
    );

    if (result.isSuccess && result.data != null) {
      return CreateEquipmentResponse.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to create equipment');
  }

  /// Update an existing equipment.
  static Future<Equipment> updateEquipment(
    String id, {
    String? name,
    String? serialNo,
    String? purchasedFrom,
    String? place,
    String? phone,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (serialNo != null) body['serialNo'] = serialNo;
    if (purchasedFrom != null) body['purchasedFrom'] = purchasedFrom;
    if (place != null) body['place'] = place;
    if (phone != null) body['phone'] = phone;
    if (status != null) body['status'] = status;

    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.equipmentEndpoint}/$id',
      body: body,
    );

    if (result.isSuccess && result.data != null) {
      return Equipment.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to update equipment');
  }

  /// Update equipment status.
  static Future<Equipment> updateStatus(String id, String status) async {
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.equipmentEndpoint}/$id',
      body: {'status': status},
    );

    if (result.isSuccess && result.data != null) {
      return Equipment.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to update equipment status');
  }

  /// Delete an equipment.
  static Future<bool> deleteEquipment(String id) async {
    final result = await ApiService.delete(
      '${ApiConfig.equipmentEndpoint}/$id',
    );

    if (result.isSuccess) {
      return true;
    }

    throw Exception(result.error ?? 'Failed to delete equipment');
  }

  /// Search equipment by name or uniqueId.
  static Future<List<Equipment>> searchEquipment(
    String query, {
    String? status,
  }) async {
    String searchQuery = '${ApiConfig.equipmentEndpoint}?search=$query';
    if (status != null) {
      searchQuery += '&status=$status';
    }

    final result = await ApiService.get<List<dynamic>>(searchQuery);

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => Equipment.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(result.error ?? 'Failed to search equipment');
  }
}
