import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/features/visit_assessment/data/visit_assessment_pdf_generator.dart';
import 'package:oruma_app/features/visit_assessment/data/visit_assessment_repository.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_flow_screen.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_list_screen.dart';
import 'package:oruma_app/models/home_visit.dart';
import 'package:oruma_app/widgets/compact_app_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final assessment = VisitAssessment(
    homeVisitId: '507f1f77bcf86cd799439011',
    patientId: '507f191e810c19729de860ea',
    patientName: 'Muhammed Ali',
    regNo: '12345',
    visitDate: DateTime(2026, 6, 23),
    timeFrom: '10:00',
    timeTo: '11:30',
  );

  test('visit assessment JSON round-trip retains v2 fields', () {
    final value = assessment.copyWith(
      previousVisitConcerns: 'Previous difficulty is improving.',
      vitals: assessment.vitals.copyWith(respiratoryRhythm: 'IR'),
      carePlan: assessment.carePlan.copyWith(
        visitPlanNotes: const {'DHC': 'Weekly day care follow-up'},
      ),
      medicines: const [
        AssessmentMedicine(
          medicineName: 'Paracetamol',
          strength: '500 mg',
          instructionSpecified: 'Yes',
          instructionUsage: '1-0-1',
          routes: {'P'},
          duration: 'June 2026',
          remarks: 'After food',
        ),
      ],
    );
    final decoded = VisitAssessment.fromJson(value.toJson());

    expect(decoded.homeVisitId, assessment.homeVisitId);
    expect(decoded.patientId, assessment.patientId);
    expect(decoded.visitType, 'NHC');
    expect(decoded.previousVisitConcerns, value.previousVisitConcerns);
    expect(decoded.vitals.respiratoryRhythm, 'IR');
    expect(decoded.medicines.single.instructionSpecified, 'Yes');
    expect(decoded.medicines.single.instructionUsage, '1-0-1');
    expect(decoded.carePlan.visitPlanNotes['DHC'], 'Weekly day care follow-up');
    expect(decoded.physicalExam.length, 18);
    expect(decoded.carePlan.visitPlans, contains('NHC'));
  });

  test('new NHC assessments start with editable adult baseline vitals', () {
    expect(assessment.vitals.pulse, 72);
    expect(assessment.vitals.bpSystolic, 120);
    expect(assessment.vitals.bpDiastolic, 80);
    expect(assessment.vitals.respiratoryRate, 16);
    expect(assessment.vitals.temperature, 98);
    expect(assessment.vitals.temperatureUnit, 'F');
    expect(assessment.vitals.spo2, 98);
    expect(assessment.vitals.grbs, 145);
    expect(assessment.vitals.activityLevel, 'IV');
  });

  test('new NHC assessments start with requested physical exam defaults', () {
    expect(assessment.physicalExam['respiration']?.value, 'normal');
    expect(assessment.physicalExam['foodWater']?.value, 'self_feeding');
    expect(
      assessment.physicalExam['urine']?.value,
      'uses_toilet_independently',
    );
    expect(assessment.physicalExam['defecation']?.value, 'normal');
    expect(assessment.physicalExam['sleep']?.value, 'normal');
    expect(assessment.physicalExam['scalpHair']?.value, 'clean');
  });

  test('older blank drafts receive baseline vitals when loaded', () {
    final draftJson = assessment.toJson()
      ..['vitals'] = {
        'pulse': null,
        'bpSystolic': null,
        'bpDiastolic': null,
        'rr': null,
        'temp': null,
        'spo2': null,
        'grbs': null,
        'bpPosition': 'LL',
      };

    final decoded = VisitAssessment.fromJson(draftJson);

    expect(decoded.vitals.pulse, 72);
    expect(decoded.vitals.bpSystolic, 120);
    expect(decoded.vitals.bpDiastolic, 80);
    expect(decoded.vitals.respiratoryRate, 16);
    expect(decoded.vitals.temperature, 98);
    expect(decoded.vitals.temperatureUnit, 'F');
    expect(decoded.vitals.spo2, 98);
    expect(decoded.vitals.grbs, 145);
    expect(decoded.vitals.activityLevel, 'IV');
    expect(decoded.vitals.bpPosition, 'LL');
  });

  test('submitted assessments do not invent missing measurements', () {
    final submittedJson = assessment.toJson()
      ..['status'] = 'submitted'
      ..['isComplete'] = true
      ..['vitals'] = {
        'pulse': null,
        'bpSystolic': null,
        'bpDiastolic': null,
        'rr': null,
        'temp': null,
        'spo2': null,
        'grbs': null,
      };

    final decoded = VisitAssessment.fromJson(submittedJson);

    expect(decoded.vitals.pulse, isNull);
    expect(decoded.vitals.bpSystolic, isNull);
    expect(decoded.vitals.respiratoryRate, isNull);
    expect(decoded.vitals.temperature, isNull);
  });

  test('submitted remote assessment wins over stale local draft', () async {
    final staleDraft = assessment.copyWith(
      previousVisitConcerns: 'stale draft data',
      status: 'draft',
      isComplete: false,
      updatedAt: DateTime(2026, 6, 26, 10),
    );
    final submitted = assessment.copyWith(
      id: 'submitted-id',
      previousVisitConcerns: 'submitted data',
      status: 'submitted',
      isComplete: true,
      updatedAt: DateTime(2026, 6, 25, 10),
      submittedAt: DateTime(2026, 6, 25, 10),
    );
    final repository = _FakeVisitAssessmentRepository(
      localDraft: staleDraft,
      remoteForVisit: submitted,
      history: [submitted],
    );
    final controller = VisitAssessmentController(
      initialAssessment: assessment,
      repository: repository,
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.assessment.previousVisitConcerns, 'submitted data');
    expect(controller.assessment.isComplete, isTrue);
    expect(repository.clearedDrafts, contains(assessment.homeVisitId));
  });

  test(
    'submit clears draft storage and keeps submitted item in history',
    () async {
      final ready = assessment.copyWith(
        id: 'draft-id',
        nursingDiagnosis: 'Routine follow-up.',
        carePlan: assessment.carePlan.copyWith(
          services: const {'healthEducation'},
        ),
        nurseName: 'Nurse A',
        confirmed: true,
      );
      final repository = _FakeVisitAssessmentRepository(history: const []);
      final controller = VisitAssessmentController(
        initialAssessment: ready,
        repository: repository,
      );
      addTearDown(controller.dispose);

      final ok = await controller.submit();

      expect(ok, isTrue);
      expect(controller.assessment.status, 'submitted');
      expect(controller.assessment.isComplete, isTrue);
      expect(repository.clearedDrafts, contains(assessment.homeVisitId));
      expect(controller.previousAssessments, hasLength(1));
      expect(controller.previousAssessments.single.id, 'draft-id');
    },
  );

  test(
    'patient-first submit creates home visit and resets current form',
    () async {
      final patientFirst = assessment.copyWith(
        homeVisitId: '',
        patientAddress: 'Kadakkadan House, Nelloliparamba',
        visitDate: DateTime(2026, 6, 26),
        nursingDiagnosis: 'Routine follow-up.',
        carePlan: assessment.carePlan.copyWith(
          services: const {'healthEducation'},
        ),
        nurseName: 'Nurse A',
        confirmed: true,
      );
      final repository = _FakeVisitAssessmentRepository(history: const []);
      final controller = VisitAssessmentController(
        initialAssessment: patientFirst,
        repository: repository,
      );
      addTearDown(controller.dispose);

      final ok = await controller.submit();

      expect(ok, isTrue);
      expect(repository.createdHomeVisits, hasLength(1));
      final createdVisit = repository.createdHomeVisits.single;
      expect(createdVisit.patientId, patientFirst.patientId);
      expect(createdVisit.patientName, patientFirst.patientName);
      expect(createdVisit.address, patientFirst.patientAddress);
      expect(createdVisit.team, patientFirst.team);
      expect(DateTime.parse(createdVisit.visitDate), DateTime(2026, 6, 26));
      expect(repository.clearedDrafts, contains('created-home-1'));
      expect(
        repository.clearedDrafts,
        contains(
          VisitAssessmentRepository.patientDateDraftKeyFor(patientFirst),
        ),
      );
      expect(controller.previousAssessments, hasLength(1));
      expect(
        controller.previousAssessments.single.homeVisitId,
        'created-home-1',
      );
      expect(controller.previousAssessments.single.status, 'submitted');
      expect(controller.assessment.homeVisitId, isEmpty);
      expect(controller.assessment.id, isNull);
      expect(controller.assessment.status, 'draft');
      expect(controller.assessment.isComplete, isFalse);
      expect(controller.assessment.nursingDiagnosis, isEmpty);
      expect(controller.assessment.medicines, isEmpty);
      expect(controller.assessment.patientId, patientFirst.patientId);
      expect(controller.hasDraftInProgress, isFalse);
    },
  );

  testWidgets('visit assessment opens with reference step header', (
    tester,
  ) async {
    final controller = VisitAssessmentController(initialAssessment: assessment);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: VisitAssessmentFlowScreen(controller: controller),
      ),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.white,
    );
    expect(find.text('Step 1 of 7'), findsOneWidget);
    expect(find.text('Visit Information'), findsOneWidget);
    expect(find.text('Muhammed Ali'), findsOneWidget);
    expect(find.text('NHC'), findsWidgets);
  });

  testWidgets('physical examination is step two and supports Malayalam', (
    tester,
  ) async {
    final controller = VisitAssessmentController(initialAssessment: assessment);
    controller.setLanguage('en');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: VisitAssessmentFlowScreen(controller: controller)),
    );

    controller.setStep(1);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Step 2 of 7'), findsOneWidget);
    expect(find.text('Physical Examination'), findsOneWidget);
    expect(
      find.text(
        "The difficulties/problems noted during the previous visit and their current status, the patient's main complaints / major difficulties / general condition.",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('ML'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('ശാരീരിക പരിശോധന'), findsOneWidget);
    expect(find.text('പ്രാഥമിക കാര്യങ്ങൾ'), findsOneWidget);
  });

  testWidgets('NHC inputs keep focus while assessment state updates', (
    tester,
  ) async {
    final controller = VisitAssessmentController(initialAssessment: assessment);
    controller.setLanguage('en');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: VisitAssessmentFlowScreen(controller: controller)),
    );

    controller.setStep(1);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Respiration'));
    await tester.pump(const Duration(milliseconds: 200));

    final notesField = find.byKey(
      const ValueKey('physical-exam-notes-respiration'),
    );
    await tester.ensureVisible(notesField);
    await tester.pump();
    final notesEditable = find.descendant(
      of: notesField,
      matching: find.byType(EditableText),
    );
    tester.widget<EditableText>(notesEditable).focusNode.requestFocus();
    await tester.pump();
    tester.testTextInput.enterText('d');
    await tester.pump();

    expect(
      tester.widget<EditableText>(notesEditable).focusNode.hasFocus,
      isTrue,
    );

    tester.testTextInput.enterText('da');
    await tester.pump();

    expect(controller.assessment.physicalExam['respiration']?.notes, 'da');
    expect(
      tester.widget<EditableText>(notesEditable).focusNode.hasFocus,
      isTrue,
    );

    controller.setStep(2);
    await tester.pump(const Duration(milliseconds: 300));
    final pulseField = find.byKey(const ValueKey('vitals-defaults-v2-pulse'));
    final pulseEditable = find.descendant(
      of: pulseField,
      matching: find.byType(EditableText),
    );
    tester.widget<EditableText>(pulseEditable).focusNode.requestFocus();
    await tester.pump();
    tester.testTextInput.enterText('7');
    await tester.pump();
    tester.testTextInput.enterText('72');
    await tester.pump();

    expect(controller.assessment.vitals.pulse, 72);
    expect(
      tester.widget<EditableText>(pulseEditable).focusNode.hasFocus,
      isTrue,
    );

    expect(find.text('Stability'), findsNothing);
    await tester.drag(find.byType(ListView).last, const Offset(0, -360));
    await tester.pump(const Duration(milliseconds: 300));
    final unstable = find.text('Unstable');
    await tester.tap(unstable);
    await tester.pump();
    expect(controller.assessment.vitals.stability, 'unstable');

    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('compact app bar exposes the five requested destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CompactAppBottomBar(
            current: AppBottomSection.home,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Patients'), findsOneWidget);
    expect(find.text('Home Visit'), findsOneWidget);
    expect(find.text('Visit (NHC)'), findsOneWidget);
  });

  testWidgets('previous assessment opens a read-only details screen', (
    tester,
  ) async {
    final controller = VisitAssessmentController(initialAssessment: assessment);
    controller.isLoading = false;
    controller.previousAssessments = [
      assessment.copyWith(
        id: '507f1f77bcf86cd799439099',
        patientAge: '54',
        status: 'submitted',
        isComplete: true,
        submittedAt: DateTime(2026, 6, 23, 12, 10),
        previousVisitConcerns: 'Breathing difficulty improved.',
        medicines: const [
          AssessmentMedicine(
            medicineName: 'Paracetamol',
            strength: '500 mg',
            instructionSpecified: 'Yes',
            instructionUsage: '1-0-1',
            routes: {'P'},
            duration: 'June 2026',
          ),
        ],
        nursingDiagnosis: 'Continue routine care.',
      ),
    ];
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: VisitAssessmentListScreen(controller: controller)),
    );

    expect(find.text('23 Jun 2026'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    await tester.tap(find.text('23 Jun 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Assessment Details'), findsOneWidget);
    expect(find.text('Breathing difficulty improved.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Paracetamol, 500 mg'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Paracetamol, 500 mg'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('completed current assessment opens details with edit action', (
    tester,
  ) async {
    final submitted = assessment.copyWith(
      id: '507f1f77bcf86cd799439099',
      status: 'submitted',
      isComplete: true,
      submittedAt: DateTime(2026, 6, 23, 12, 10),
      nursingDiagnosis: 'Routine care completed.',
    );
    final controller = VisitAssessmentController(initialAssessment: submitted);
    controller.isLoading = false;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: VisitAssessmentListScreen(controller: controller)),
    );

    expect(find.text('New Assessment'), findsOneWidget);
    await tester.tap(find.text('New Assessment'));
    await tester.pumpAndSettle();

    expect(find.text('Assessment Details'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('visit assessment PDF generator creates exactly two pages', (
    tester,
  ) async {
    final value = assessment.copyWith(
      patientAge: '54',
      previousVisitConcerns: 'ശ്വാസ ബുദ്ധിമുട്ട് കുറഞ്ഞു. Appetite better.',
      vitals: assessment.vitals.copyWith(
        pulse: 72,
        bpSystolic: 120,
        bpDiastolic: 80,
        respiratoryRate: 16,
        temperature: 37,
        spo2: 98,
        grbs: 100,
      ),
      physicalExam: {
        ...assessment.physicalExam,
        'respiration': const ExamFinding(
          status: 'normal',
          notes: 'ശ്വാസം സാധാരണ നിലയിൽ.',
        ),
      },
      medicines: const [
        AssessmentMedicine(
          medicineName: 'Paracetamol',
          strength: '500 mg',
          instructionSpecified: 'Yes',
          instructionUsage: '1-0-1',
          routes: {'P'},
          duration: 'June 2026',
          remarks: 'Fever only',
        ),
      ],
      medicineRemarks: 'No drug allergy reported.',
      nursingDiagnosis: 'Routine palliative follow-up.',
      doctorConsultNotes: 'Doctor consult if fever persists.',
      nursingManagementPlan: 'Continue monitoring vitals.',
      carePlan: assessment.carePlan.copyWith(
        visitPlanNotes: const {'NHC': 'Next NHC visit planned.'},
        services: const {'healthEducation', 'medicineSupport'},
      ),
      teamMeetingDiscussion: 'Family educated about medicine usage.',
      nurseName: 'Nurse A',
      status: 'submitted',
      isComplete: true,
    );

    final bytes = await VisitAssessmentPdfGenerator.generate(value);
    final header = ascii.decode(bytes.take(4).toList());
    final pdfText = latin1.decode(bytes, allowInvalid: true);

    expect(header, '%PDF');
    expect(RegExp(r'/Type /Page\b').allMatches(pdfText), hasLength(2));
  });

  testWidgets('medicine step uses editable table inputs', (tester) async {
    final controller = VisitAssessmentController(initialAssessment: assessment);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: VisitAssessmentFlowScreen(controller: controller)),
    );

    controller.setStep(3);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Medicines'), findsOneWidget);
    expect(find.text('Add Row'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('medicine-name-strength-0')),
      'Paracetamol, 500 mg',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('medicine-instruction-specified-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('medicine-instruction-usage-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('1-0-1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('medicine-route-p-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('medicine-duration-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jun').last);
    await tester.pumpAndSettle();

    expect(controller.assessment.medicines, hasLength(1));
    final medicine = controller.assessment.medicines.single;
    final selectedMonth = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(DateTime.now().year, 6));
    expect(medicine.medicineName, 'Paracetamol');
    expect(medicine.strength, '500 mg');
    expect(medicine.instructionSpecified, 'Yes');
    expect(medicine.instructionUsage, '1-0-1');
    expect(medicine.routes, contains('P'));
    expect(medicine.duration, selectedMonth);

    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('care plan captures visit type row dates', (tester) async {
    final controller = VisitAssessmentController(initialAssessment: assessment);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: VisitAssessmentFlowScreen(controller: controller)),
    );

    controller.setStep(5);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('care-plan-visit-DHC')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();

    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    expect(controller.assessment.carePlan.visitPlans, contains('DHC'));
    expect(controller.assessment.carePlan.visitPlanNotes['DHC'], today);

    await tester.pump(const Duration(milliseconds: 700));
  });
}

class _FakeVisitAssessmentRepository extends VisitAssessmentRepository {
  _FakeVisitAssessmentRepository({
    this.localDraft,
    this.remoteForVisit,
    List<VisitAssessment> history = const [],
  }) : history = [...history];

  VisitAssessment? localDraft;
  VisitAssessment? remoteForVisit;
  List<VisitAssessment> history;
  final clearedDrafts = <String>[];
  final savedLocalDrafts = <VisitAssessment>[];
  final savedDraftAliases = <String, VisitAssessment>{};
  final createdHomeVisits = <HomeVisit>[];

  @override
  Future<VisitAssessment?> loadLocalDraft(String draftKey) async =>
      savedDraftAliases[draftKey] ?? localDraft;

  @override
  Future<void> saveLocalDraft(VisitAssessment assessment) async {
    savedLocalDrafts.add(assessment);
    savedDraftAliases[VisitAssessmentRepository.draftKeyFor(assessment)] =
        assessment;
    localDraft = assessment;
  }

  @override
  Future<void> saveLocalDraftForKey(
    String draftKey,
    VisitAssessment assessment,
  ) async {
    savedDraftAliases[draftKey] = assessment;
    localDraft = assessment;
  }

  @override
  Future<void> clearLocalDraft(String draftKey) async {
    clearedDrafts.add(draftKey);
    savedDraftAliases.remove(draftKey);
    if (localDraft != null &&
        (VisitAssessmentRepository.draftKeyFor(localDraft!) == draftKey ||
            VisitAssessmentRepository.patientDateDraftKeyFor(localDraft!) ==
                draftKey)) {
      localDraft = null;
    }
  }

  @override
  Future<List<VisitAssessment>> getHistory(String patientId) async => history;

  @override
  Future<void> cacheAssessmentInHistory(VisitAssessment assessment) async {
    final index = history.indexWhere((item) {
      if (assessment.id != null && item.id == assessment.id) return true;
      return item.homeVisitId == assessment.homeVisitId;
    });
    if (index >= 0) {
      history[index] = assessment;
    } else {
      history.add(assessment);
    }
  }

  @override
  Future<VisitAssessment?> getRemoteForVisit(String homeVisitId) async =>
      remoteForVisit;

  @override
  Future<VisitAssessment> syncDraft(VisitAssessment assessment) async =>
      assessment.id == null ? assessment.copyWith(id: 'draft-id') : assessment;

  @override
  Future<HomeVisit> createHomeVisitForAssessment(
    VisitAssessment assessment,
  ) async {
    final visit = HomeVisit(
      id: 'created-home-${createdHomeVisits.length + 1}',
      patientId: assessment.patientId,
      patientName: assessment.patientName,
      address: assessment.patientAddress,
      visitDate: assessment.visitDate.toIso8601String(),
      visitMode: 'new',
      team: assessment.team,
      notes: 'Created from Visit (NHC) assessment',
    );
    createdHomeVisits.add(visit);
    return visit;
  }

  @override
  Future<VisitAssessment> submit(VisitAssessment assessment) async =>
      assessment.copyWith(
        status: 'submitted',
        isComplete: true,
        submittedAt: DateTime(2026, 6, 26, 10),
      );
}
