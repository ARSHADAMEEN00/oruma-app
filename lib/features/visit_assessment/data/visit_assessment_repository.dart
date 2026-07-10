import 'dart:convert';

import 'package:oruma_app/features/visit_assessment/data/visit_assessment_service.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:oruma_app/models/home_visit.dart';
import 'package:oruma_app/services/home_visit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisitAssessmentRepository {
  static const _draftPrefix = 'visit_assessment_draft_';
  static const _historyPrefix = 'visit_assessment_history_';

  static String draftKeyFor(VisitAssessment assessment) {
    if (assessment.homeVisitId.trim().isNotEmpty) {
      return assessment.homeVisitId;
    }
    return patientDateDraftKeyFor(assessment);
  }

  static String patientDateDraftKeyFor(VisitAssessment assessment) {
    final dateKey = assessment.visitDate.toIso8601String().split('T').first;
    return 'patient_${assessment.patientId}_$dateKey';
  }

  Future<VisitAssessment?> loadLocalDraft(String draftKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_draftPrefix$draftKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final assessment = VisitAssessment.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      final canonicalKey = draftKeyFor(assessment);
      final patientDateKey = patientDateDraftKeyFor(assessment);
      if ((canonicalKey != draftKey && patientDateKey != draftKey) ||
          assessment.status == 'submitted' ||
          assessment.isComplete) {
        await clearLocalDraft(draftKey);
        return null;
      }
      return assessment;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLocalDraft(VisitAssessment assessment) async {
    if (assessment.status == 'submitted' || assessment.isComplete) {
      await clearLocalDraft(draftKeyFor(assessment));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await _saveLocalDraftForKey(prefs, draftKeyFor(assessment), assessment);
  }

  Future<void> saveLocalDraftForKey(
    String draftKey,
    VisitAssessment assessment,
  ) async {
    if (assessment.status == 'submitted' || assessment.isComplete) {
      await clearLocalDraft(draftKey);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await _saveLocalDraftForKey(prefs, draftKey, assessment);
  }

  Future<void> clearLocalDraft(String draftKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_draftPrefix$draftKey');
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

  Future<void> cacheAssessmentInHistory(VisitAssessment assessment) async {
    if (assessment.patientId.isEmpty) return;
    final history = await loadCachedHistory(assessment.patientId);
    await cacheHistory(
      assessment.patientId,
      _mergeHistory(history, assessment),
    );
  }

  Future<void> removeAssessmentFromHistory(VisitAssessment assessment) async {
    if (assessment.patientId.isEmpty) return;

    final history = await loadCachedHistory(assessment.patientId);
    final filtered = history
        .where((item) => !_isSameAssessment(item, assessment))
        .toList();
    await cacheHistory(assessment.patientId, filtered);
    await clearLocalDraft(draftKeyFor(assessment));
    await clearLocalDraft(patientDateDraftKeyFor(assessment));
    if (assessment.homeVisitId.trim().isNotEmpty) {
      await clearLocalDraft(assessment.homeVisitId);
    }
  }

  Future<List<VisitAssessment>> getHistory(String patientId) async {
    try {
      final remote = await VisitAssessmentService.getAssessments(
        patientId: patientId,
      );
      final cached = await loadCachedHistory(patientId);
      final cachedDrafts = cached
          .where((item) => item.status != 'submitted' && !item.isComplete)
          .toList();
      final merged = _mergeHistories(remote, cachedDrafts);
      await cacheHistory(patientId, merged);
      return merged;
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

  Future<HomeVisit> createHomeVisitForAssessment(VisitAssessment assessment) {
    final visit = HomeVisit(
      patientId: assessment.patientId,
      patientName: assessment.patientName,
      address: assessment.patientAddress.trim().isNotEmpty
          ? assessment.patientAddress.trim()
          : 'Address not recorded',
      visitDate: assessment.visitDate.toIso8601String(),
      visitMode: assessment.visitMode.trim().isNotEmpty
          ? assessment.visitMode
          : 'new',
      team: assessment.team.trim().isNotEmpty ? assessment.team.trim() : null,
      notes: 'Created from Visit (NHC) assessment',
    );
    return HomeVisitService.createHomeVisit(visit);
  }

  Future<void> _saveLocalDraftForKey(
    SharedPreferences prefs,
    String draftKey,
    VisitAssessment assessment,
  ) {
    return prefs.setString(
      '$_draftPrefix$draftKey',
      jsonEncode(assessment.toJson()),
    );
  }

  List<VisitAssessment> _mergeHistory(
    List<VisitAssessment> history,
    VisitAssessment assessment,
  ) {
    final merged = [...history];
    final index = merged.indexWhere(
      (item) => _isSameAssessment(item, assessment),
    );
    if (index >= 0) {
      merged[index] = assessment;
    } else {
      merged.add(assessment);
    }
    merged.sort((a, b) {
      final dateCompare = b.visitDate.compareTo(a.visitDate);
      if (dateCompare != 0) return dateCompare;
      final aUpdated = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bUpdated = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bUpdated.compareTo(aUpdated);
    });
    return merged;
  }

  List<VisitAssessment> _mergeHistories(
    List<VisitAssessment> primary,
    List<VisitAssessment> secondary,
  ) {
    var merged = [...primary];
    for (final assessment in secondary) {
      final exists = merged.any((item) => _isSameAssessment(item, assessment));
      if (!exists) merged = _mergeHistory(merged, assessment);
    }
    return merged;
  }

  bool _isSameAssessment(VisitAssessment a, VisitAssessment b) {
    if (a.id != null && b.id != null && a.id == b.id) return true;
    if (a.homeVisitId.trim().isNotEmpty &&
        b.homeVisitId.trim().isNotEmpty &&
        a.homeVisitId == b.homeVisitId) {
      return true;
    }
    return a.patientId == b.patientId &&
        patientDateDraftKeyFor(a) == patientDateDraftKeyFor(b);
  }
}
