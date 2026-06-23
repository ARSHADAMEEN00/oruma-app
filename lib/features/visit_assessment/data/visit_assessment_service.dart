import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:oruma_app/services/api_config.dart';
import 'package:oruma_app/services/api_service.dart';

class VisitAssessmentService {
  VisitAssessmentService._();

  static Future<List<VisitAssessment>> getAssessments({
    String? patientId,
    String? homeVisitId,
  }) async {
    final query = <String, String>{
      if (patientId?.isNotEmpty == true) 'patientId': patientId!,
      if (homeVisitId?.isNotEmpty == true) 'homeVisitId': homeVisitId!,
    };
    final uri = Uri.parse(
      ApiConfig.visitAssessmentsEndpoint,
    ).replace(queryParameters: query.isEmpty ? null : query);
    final result = await ApiService.get<List<dynamic>>(uri.toString());
    if (result.isSuccess && result.data != null) {
      return result.data!
          .whereType<Map>()
          .map(
            (item) => VisitAssessment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    throw Exception(result.error ?? 'Failed to fetch visit assessments');
  }

  static Future<VisitAssessment> saveDraft(VisitAssessment assessment) async {
    final endpoint = assessment.id == null
        ? ApiConfig.visitAssessmentsEndpoint
        : '${ApiConfig.visitAssessmentsEndpoint}/${assessment.id}';
    final result = assessment.id == null
        ? await ApiService.post<Map<String, dynamic>>(
            endpoint,
            body: assessment.toJson(),
          )
        : await ApiService.put<Map<String, dynamic>>(
            endpoint,
            body: assessment.toJson(),
          );
    if (result.isSuccess && result.data != null) {
      return VisitAssessment.fromJson(result.data!);
    }
    throw Exception(result.error ?? 'Failed to save assessment draft');
  }

  static Future<VisitAssessment> submit(VisitAssessment assessment) async {
    if (assessment.id == null) {
      throw StateError('Save the draft before submitting');
    }
    final result = await ApiService.post<Map<String, dynamic>>(
      '${ApiConfig.visitAssessmentsEndpoint}/${assessment.id}/submit',
      body: assessment.toJson(),
    );
    if (result.isSuccess && result.data != null) {
      return VisitAssessment.fromJson(result.data!);
    }
    throw Exception(result.error ?? 'Failed to submit visit assessment');
  }
}
