import 'dart:convert';

import 'package:oruma_app/features/visit_assessment/data/visit_assessment_service.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisitAssessmentRepository {
  static const _draftPrefix = 'visit_assessment_draft_';
  static const _historyPrefix = 'visit_assessment_history_';

  Future<VisitAssessment?> loadLocalDraft(String homeVisitId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_draftPrefix$homeVisitId');
    if (raw == null || raw.isEmpty) return null;
    try {
      return VisitAssessment.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLocalDraft(VisitAssessment assessment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_draftPrefix${assessment.homeVisitId}',
      jsonEncode(assessment.toJson()),
    );
  }

  Future<void> clearLocalDraft(String homeVisitId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_draftPrefix$homeVisitId');
  }

  Future<List<VisitAssessment>> loadCachedHistory(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_historyPrefix$patientId');
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map(
            (item) => VisitAssessment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheHistory(
    String patientId,
    List<VisitAssessment> assessments,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_historyPrefix$patientId',
      jsonEncode(assessments.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<VisitAssessment>> getHistory(String patientId) async {
    try {
      final remote = await VisitAssessmentService.getAssessments(
        patientId: patientId,
      );
      await cacheHistory(patientId, remote);
      return remote;
    } catch (_) {
      return loadCachedHistory(patientId);
    }
  }

  Future<VisitAssessment?> getRemoteForVisit(String homeVisitId) async {
    final list = await VisitAssessmentService.getAssessments(
      homeVisitId: homeVisitId,
    );
    return list.isEmpty ? null : list.first;
  }

  Future<VisitAssessment> syncDraft(VisitAssessment assessment) =>
      VisitAssessmentService.saveDraft(assessment);

  Future<VisitAssessment> submit(VisitAssessment assessment) =>
      VisitAssessmentService.submit(assessment);
}
