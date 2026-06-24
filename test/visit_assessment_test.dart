import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_flow_screen.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_list_screen.dart';
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
          instructionSpecified: '1-0-1',
          instructionUsage: 'As needed',
          routes: {'P'},
          duration: '3 days',
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
    expect(decoded.medicines.single.instructionSpecified, '1-0-1');
    expect(decoded.medicines.single.instructionUsage, 'As needed');
    expect(decoded.carePlan.visitPlanNotes['DHC'], 'Weekly day care follow-up');
    expect(decoded.physicalExam.length, 18);
    expect(decoded.carePlan.visitPlans, contains('NHC'));
  });

  test('new NHC assessments start with editable adult baseline vitals', () {
    expect(assessment.vitals.pulse, 72);
    expect(assessment.vitals.bpSystolic, 120);
    expect(assessment.vitals.bpDiastolic, 80);
    expect(assessment.vitals.respiratoryRate, 16);
    expect(assessment.vitals.temperature, 37);
    expect(assessment.vitals.spo2, 98);
    expect(assessment.vitals.grbs, 100);
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
    expect(decoded.vitals.temperature, 37);
    expect(decoded.vitals.spo2, 98);
    expect(decoded.vitals.grbs, 100);
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
    final unstable = find.text('Unstable');
    await tester.ensureVisible(unstable);
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
            instructionSpecified: '1-0-1',
            instructionUsage: 'After food',
            routes: {'P'},
            duration: '3 days',
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
    await tester.enterText(
      find.byKey(const ValueKey('medicine-instruction-specified-0')),
      '1-0-1',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('medicine-instruction-usage-0')),
      'As needed',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('medicine-route-p-0')),
      'x',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('medicine-duration-0')),
      '3 days',
    );
    await tester.pump();

    expect(controller.assessment.medicines, hasLength(1));
    final medicine = controller.assessment.medicines.single;
    expect(medicine.medicineName, 'Paracetamol');
    expect(medicine.strength, '500 mg');
    expect(medicine.instructionSpecified, '1-0-1');
    expect(medicine.instructionUsage, 'As needed');
    expect(medicine.routes, contains('P'));
    expect(medicine.duration, '3 days');

    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('care plan captures visit type row notes', (tester) async {
    final controller = VisitAssessmentController(initialAssessment: assessment);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: VisitAssessmentFlowScreen(controller: controller)),
    );

    controller.setStep(5);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const ValueKey('care-plan-visit-DHC')),
      'Weekly day care follow-up',
    );
    await tester.pump();

    expect(controller.assessment.carePlan.visitPlans, contains('DHC'));
    expect(
      controller.assessment.carePlan.visitPlanNotes['DHC'],
      'Weekly day care follow-up',
    );

    await tester.pump(const Duration(milliseconds: 700));
  });
}
