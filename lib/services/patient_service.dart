import '../models/patient.dart';
import 'api_config.dart';
import 'api_service.dart';

/// Patient service for CRUD operations via the backend API.
class PatientService {
  PatientService._();

  /// Get all patients from the API.
  static Future<List<Patient>> getAllPatients({bool? isDead}) async {
    // Adapter for legacy calls
    String filter = 'all';
    if (isDead == true) {
      filter = 'dead';
    } else if (isDead == false) {
      filter = 'alive';
    }

    final response = await getPatientsList(filter: filter);
    return response.patients;
  }


  /// Get patients with filter and counts.
  static Future<PatientListResponse> getPatientsList({String filter = 'all'}) async {
    final query =
        '${ApiConfig.patientsEndpoint}?filter=$filter&populate=createdBy';
    final result = await ApiService.get<dynamic>(query);

    if (result.isSuccess && result.data != null) {
      if (result.data is Map<String, dynamic>) {
        return PatientListResponse.fromJson(result.data as Map<String, dynamic>);
      } else if (result.data is List) {
        // Fallback for legacy API response (returns List instead of Map)
        final list = (result.data as List)
            .map((json) => Patient.fromJson(json as Map<String, dynamic>))
            .toList();

        // Calculate counts based on the received list
        final allCount = list.length;
        final deadCount = list.where((p) => p.isDead).length;
        final aliveCount = list.where((p) => !p.isDead).length;

        return PatientListResponse(
          patients: list,
          counts: PatientCounts(
            allCount: allCount,
            deadCount: deadCount,
            aliveCount: aliveCount,
          ),
        );
      }
    }

    throw Exception(result.error ?? 'Failed to fetch patients');
  }

  /// Get a single patient by ID.
  static Future<Patient> getPatientById(String id) async {
    final result = await ApiService.get<Map<String, dynamic>>(
      '${ApiConfig.patientsEndpoint}/$id?populate=createdBy',
    );

    if (result.isSuccess && result.data != null) {
      return Patient.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to fetch patient');
  }

  /// Create a new patient.
  static Future<Patient> createPatient(Patient patient) async {
    final result = await ApiService.post<Map<String, dynamic>>(
      ApiConfig.patientsEndpoint,
      body: patient.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      return Patient.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to create patient');
  }

  /// Update an existing patient.
  static Future<Patient> updatePatient(String id, Patient patient) async {
    final result = await ApiService.put<Map<String, dynamic>>(
      '${ApiConfig.patientsEndpoint}/$id',
      body: patient.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      return Patient.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to update patient');
  }

  /// Delete a patient.
  static Future<bool> deletePatient(String id) async {
    final result = await ApiService.delete('${ApiConfig.patientsEndpoint}/$id');

    if (result.isSuccess) {
      return true;
    }

    throw Exception(result.error ?? 'Failed to delete patient');
  }

  /// Search patients by name.
  static Future<List<Patient>> searchPatients(
    String query, {
    bool? isDead,
  }) async {
    String searchQuery =
        '${ApiConfig.patientsEndpoint}?search=$query&populate=createdBy';
    if (isDead != null) {
      searchQuery += '&isDead=$isDead';
    }

    final result = await ApiService.get<List<dynamic>>(searchQuery);

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => Patient.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(result.error ?? 'Failed to search patients');
  }
}
