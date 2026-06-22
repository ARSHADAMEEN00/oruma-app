import '../models/patient_details.dart';
import 'api_config.dart';
import 'api_service.dart';

class PatientDetailsService {
  PatientDetailsService._();

  static Future<PatientDetails> getPatientDetails(String patientId) async {
    final result = await ApiService.get<Map<String, dynamic>>(
      '${ApiConfig.v2PatientsEndpoint}/$patientId/details',
    );

    if (result.isSuccess && result.data != null) {
      return PatientDetails.fromJson(result.data!);
    }

    throw Exception(result.error ?? 'Failed to fetch patient details');
  }
}
