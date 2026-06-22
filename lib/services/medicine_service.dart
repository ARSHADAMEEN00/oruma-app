import '../models/medicine.dart';
import 'api_config.dart';
import 'api_service.dart';

class MedicineService {
  MedicineService._();

  static Future<List<Medicine>> getMedicines({String? search}) async {
    var url = ApiConfig.v2MedicinesEndpoint;
    if (search?.trim().isNotEmpty == true) {
      url += '?search=${Uri.encodeQueryComponent(search!.trim())}';
    }

    final result = await ApiService.get<List<dynamic>>(url);
    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((item) => Medicine.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception(result.error ?? 'Failed to fetch medicines');
  }

  static Future<Medicine> createMedicine(Medicine medicine) async {
    final result = await ApiService.post<Map<String, dynamic>>(
      ApiConfig.v2MedicinesEndpoint,
      body: medicine.toJson(),
    );
    if (result.isSuccess && result.data != null) {
      return Medicine.fromJson(result.data!);
    }
    throw Exception(result.error ?? 'Failed to create medicine');
  }

  static Future<Medicine> updateMedicine(String id, Medicine medicine) async {
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.v2MedicinesEndpoint}/$id',
      body: medicine.toJson(),
    );
    if (result.isSuccess && result.data != null) {
      return Medicine.fromJson(result.data!);
    }
    throw Exception(result.error ?? 'Failed to update medicine');
  }

  static Future<bool> deleteMedicine(String id) async {
    final result = await ApiService.delete(
      '${ApiConfig.v2MedicinesEndpoint}/$id',
    );
    if (result.isSuccess) return true;
    throw Exception(result.error ?? 'Failed to delete medicine');
  }
}
