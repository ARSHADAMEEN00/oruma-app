import '../models/patient.dart';
import 'api_config.dart';
import 'api_service.dart';

/// Patient service for CRUD operations via the backend API.
class PatientService {
  PatientService._();

  /// Get all patients from the API.
  static Future<List<Patient>> getAllPatients() async {
    final result = await ApiService.get<List<dynamic>>(
      ApiConfig.patientsEndpoint,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => Patient.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(result.error ?? 'Failed to fetch patients');
  }

  /// Get a single patient by ID.
  static Future<Patient> getPatientById(String id) async {
    final result = await ApiService.get<Map<String, dynamic>>(
      '${ApiConfig.patientsEndpoint}/$id',
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
}
