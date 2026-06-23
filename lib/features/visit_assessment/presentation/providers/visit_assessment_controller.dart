import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:oruma_app/features/visit_assessment/data/visit_assessment_repository.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';

enum AssessmentSyncState { idle, saving, saved, offline, error }

class VisitAssessmentController extends ChangeNotifier {
  VisitAssessmentController({
    required VisitAssessment initialAssessment,
    VisitAssessmentRepository? repository,
  }) : _assessment = initialAssessment,
       _repository = repository ?? VisitAssessmentRepository();

  final VisitAssessmentRepository _repository;
  VisitAssessment _assessment;
  Timer? _autoSaveTimer;
  Timer? _localSaveDebounce;
  bool _disposed = false;

  VisitAssessment get assessment => _assessment;
  List<VisitAssessment> previousAssessments = [];
  AssessmentSyncState syncState = AssessmentSyncState.idle;
  String? syncMessage;
  bool isLoading = true;
  bool isSubmitting = false;
  int currentStep = 0;

  Future<void> initialize() async {
    isLoading = true;
    _notify();

    final local = await _repository.loadLocalDraft(_assessment.homeVisitId);
    VisitAssessment? remote;
    try {
      remote = await _repository.getRemoteForVisit(_assessment.homeVisitId);
    } catch (_) {
      syncState = AssessmentSyncState.offline;
      syncMessage = 'Offline — changes are saved on this device';
    }

    if (local != null && remote != null) {
      final localTime =
          local.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final remoteTime =
          remote.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      _assessment = localTime.isAfter(remoteTime) ? local : remote;
    } else {
      _assessment = local ?? remote ?? _assessment;
    }

    previousAssessments = await _repository.getHistory(_assessment.patientId);
    previousAssessments = previousAssessments
        .where((item) => item.homeVisitId != _assessment.homeVisitId)
        .toList();
    isLoading = false;
    _startAutoSave();
    _notify();
  }

  void setStep(int step) {
    currentStep = step.clamp(0, 6);
    _notify();
  }

  void update(VisitAssessment Function(VisitAssessment value) transform) {
    _assessment = transform(
      _assessment,
    ).copyWith(updatedAt: DateTime.now(), status: 'draft', isComplete: false);
    syncState = AssessmentSyncState.idle;
    syncMessage = null;
    _scheduleLocalSave();
    _notify();
  }

  void updateVitals(VisitVitals Function(VisitVitals value) transform) {
    update((value) => value.copyWith(vitals: transform(value.vitals)));
  }

  void addMedicine(AssessmentMedicine medicine) {
    update(
      (value) => value.copyWith(medicines: [...value.medicines, medicine]),
    );
  }

  void replaceMedicine(int index, AssessmentMedicine medicine) {
    final medicines = [..._assessment.medicines];
    medicines[index] = medicine;
    update((value) => value.copyWith(medicines: medicines));
  }

  void removeMedicine(int index) {
    final medicines = [..._assessment.medicines]..removeAt(index);
    update((value) => value.copyWith(medicines: medicines));
  }

  void copyMedicinesFromPrevious() {
    VisitAssessment? source;
    for (final item in previousAssessments) {
      if (item.medicines.isNotEmpty) {
        source = item;
        break;
      }
    }
    if (source == null) return;
    final selectedSource = source;
    update(
      (value) => value.copyWith(
        medicines: selectedSource.medicines
            .map(
              (item) => AssessmentMedicine(
                medicineId: item.medicineId,
                medicineName: item.medicineName,
                strength: item.strength,
                routes: {...item.routes},
                duration: item.duration,
                remarks: item.remarks,
              ),
            )
            .toList(),
      ),
    );
  }

  void updateFinding(
    String key,
    ExamFinding Function(ExamFinding value) transform,
  ) {
    final findings = {..._assessment.physicalExam};
    findings[key] = transform(findings[key] ?? const ExamFinding());
    update((value) => value.copyWith(physicalExam: findings));
  }

  void toggleVisitPlan(String value) {
    final selected = {..._assessment.carePlan.visitPlans};
    selected.contains(value) ? selected.remove(value) : selected.add(value);
    update(
      (item) =>
          item.copyWith(carePlan: item.carePlan.copyWith(visitPlans: selected)),
    );
  }

  void toggleService(String value) {
    final selected = {..._assessment.carePlan.services};
    selected.contains(value) ? selected.remove(value) : selected.add(value);
    update(
      (item) =>
          item.copyWith(carePlan: item.carePlan.copyWith(services: selected)),
    );
  }

  String? validateStep(int step) {
    switch (step) {
      case 0:
        if (_assessment.patientId.isEmpty || _assessment.homeVisitId.isEmpty) {
          return 'This assessment needs a linked patient and home visit.';
        }
        if (_assessment.regNo.trim().isEmpty) {
          return 'Register number is required.';
        }
        if (_assessment.timeFrom.isEmpty || _assessment.timeTo.isEmpty) {
          return 'Add the visit start and end time.';
        }
        if (_assessment.team.trim().isEmpty) {
          return 'Select or enter the visiting team.';
        }
        return null;
      case 1:
        final vitals = _assessment.vitals;
        if (vitals.pulse == null ||
            vitals.bpSystolic == null ||
            vitals.bpDiastolic == null ||
            vitals.respiratoryRate == null ||
            vitals.temperature == null ||
            vitals.spo2 == null) {
          return 'Complete the core vital measurements.';
        }
        if (vitals.spo2! < 0 || vitals.spo2! > 100) {
          return 'SpO₂ must be between 0 and 100.';
        }
        return null;
      case 2:
        if (_assessment.medicines.any(
          (medicine) => medicine.medicineName.trim().isEmpty,
        )) {
          return 'Every medicine needs a name.';
        }
        return null;
      case 3:
        return null;
      case 4:
        if (_assessment.nursingDiagnosis.trim().isEmpty) {
          return 'Add the nursing diagnosis before continuing.';
        }
        return null;
      case 5:
        if (_assessment.carePlan.visitPlans.isEmpty) {
          return 'Select at least one visit plan.';
        }
        if (_assessment.carePlan.services.isEmpty) {
          return 'Select at least one required service.';
        }
        return null;
      case 6:
        for (var step = 0; step < 6; step++) {
          final error = validateStep(step);
          if (error != null) return error;
        }
        if (_assessment.nurseName.trim().isEmpty) {
          return 'Nurse name is required.';
        }
        if (_assessment.signatureUrl.isEmpty) {
          return 'Add the nurse signature.';
        }
        if (!_assessment.confirmed) {
          return 'Confirm that the assessment information is correct.';
        }
        return null;
      default:
        return null;
    }
  }

  Future<bool> saveDraft({bool silent = false}) async {
    if (syncState == AssessmentSyncState.saving) return false;
    syncState = AssessmentSyncState.saving;
    if (!silent) syncMessage = 'Saving draft…';
    _notify();

    final localValue = _assessment.copyWith(updatedAt: DateTime.now());
    _assessment = localValue;
    await _repository.saveLocalDraft(localValue);

    try {
      final synced = await _repository.syncDraft(localValue);
      _assessment = synced;
      await _repository.saveLocalDraft(synced);
      syncState = AssessmentSyncState.saved;
      syncMessage = 'Draft saved';
      _notify();
      return true;
    } catch (_) {
      syncState = AssessmentSyncState.offline;
      syncMessage = 'Saved offline — sync will retry automatically';
      _notify();
      return false;
    }
  }

  Future<bool> submit() async {
    final validationError = validateStep(6);
    if (validationError != null) {
      syncState = AssessmentSyncState.error;
      syncMessage = validationError;
      _notify();
      return false;
    }

    isSubmitting = true;
    syncMessage = 'Submitting assessment…';
    _notify();
    try {
      var value = _assessment;
      if (value.id == null) {
        value = await _repository.syncDraft(value);
      }
      final submitted = await _repository.submit(
        value.copyWith(status: 'submitted', isComplete: true),
      );
      _assessment = submitted;
      await _repository.clearLocalDraft(submitted.homeVisitId);
      syncState = AssessmentSyncState.saved;
      syncMessage = 'Assessment submitted';
      isSubmitting = false;
      _notify();
      return true;
    } catch (_) {
      await _repository.saveLocalDraft(_assessment);
      syncState = AssessmentSyncState.offline;
      syncMessage = 'Could not submit. The draft remains safely stored.';
      isSubmitting = false;
      _notify();
      return false;
    }
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => saveDraft(silent: true),
    );
  }

  void _scheduleLocalSave() {
    _localSaveDebounce?.cancel();
    _localSaveDebounce = Timer(const Duration(milliseconds: 650), () async {
      await _repository.saveLocalDraft(_assessment);
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoSaveTimer?.cancel();
    _localSaveDebounce?.cancel();
    _repository.saveLocalDraft(_assessment);
    super.dispose();
  }
}
