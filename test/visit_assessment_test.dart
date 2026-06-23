import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_flow_screen.dart';
import 'package:oruma_app/widgets/compact_app_bottom_bar.dart';

void main() {
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
    final decoded = VisitAssessment.fromJson(assessment.toJson());

    expect(decoded.homeVisitId, assessment.homeVisitId);
    expect(decoded.patientId, assessment.patientId);
    expect(decoded.visitType, 'NHC');
    expect(decoded.physicalExam.length, 18);
    expect(decoded.carePlan.visitPlans, contains('NHC'));
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
    expect(find.text('Equipment'), findsOneWidget);
    expect(find.text('Home Visit'), findsOneWidget);
    expect(find.text('NHC'), findsOneWidget);
  });
}
