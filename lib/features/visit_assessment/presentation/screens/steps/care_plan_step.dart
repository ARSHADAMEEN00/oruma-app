import 'package:flutter/material.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';

class CarePlanStep extends StatefulWidget {
  const CarePlanStep({super.key, required this.controller});

  final VisitAssessmentController controller;

  @override
  State<CarePlanStep> createState() => _CarePlanStepState();
}

class _CarePlanStepState extends State<CarePlanStep> {
  late final TextEditingController _discussion;

  static const _services = <String, (String, IconData)>{
    'healthEducation': ('Health\nEducation', Icons.health_and_safety_outlined),
    'familyTraining': ('Family\nTraining', Icons.family_restroom_outlined),
    'physiotherapy': ('Physiotherapy', Icons.accessibility_new_outlined),
    'dayCare': ('Day Care', Icons.home_work_outlined),
    'socialSupport': ('Social\nSupport', Icons.people_outline),
    'medicineSupport': ('Medicine\nSupport', Icons.medical_services_outlined),
  };

  @override
  void initState() {
    super.initState();
    _discussion = TextEditingController(
      text: widget.controller.assessment.teamMeetingDiscussion,
    );
  }

  @override
  void dispose() {
    _discussion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.controller.assessment.carePlan;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      children: [
        const AssessmentSectionTitle('Care Plan'),
        const SizedBox(height: 15),
        const AssessmentLabel('Visit Type Plan', required: true),
        AssessmentMultiSegment(
          options: const ['NHC', 'DHC', 'GVHC', 'other'],
          labels: const {'other': 'Other'},
          selected: plan.visitPlans,
          onToggle: widget.controller.toggleVisitPlan,
        ),
        const SizedBox(height: 18),
        const AssessmentLabel('Services Required', required: true),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 9) / 2;
            return Wrap(
              spacing: 9,
              runSpacing: 9,
              children: _services.entries.map((entry) {
                final active = plan.services.contains(entry.key);
                return SizedBox(
                  width: width,
                  child: InkWell(
                    onTap: () => widget.controller.toggleService(entry.key),
                    borderRadius: BorderRadius.circular(9),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 68,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: active ? assessmentMint : Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: active ? assessmentGreen : assessmentBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            entry.value.$2,
                            size: 23,
                            color: active
                                ? assessmentGreenDark
                                : assessmentMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value.$1,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? assessmentGreenDark
                                    : assessmentText,
                              ),
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: active ? assessmentGreen : Colors.white,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: active
                                    ? assessmentGreen
                                    : assessmentBorder,
                              ),
                            ),
                            child: active
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 11,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 18),
        const AssessmentLabel('Team Meeting Discussion'),
        AssessmentTextField(
          controller: _discussion,
          minLines: 3,
          maxLines: 5,
          hint: 'Optional discussion points for the care team',
          onChanged: (value) => widget.controller.update(
            (item) => item.copyWith(teamMeetingDiscussion: value),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: AssessmentVoiceButton(
            label: 'Add by voice',
            onWords: (words) {
              final current = _discussion.text.trim();
              _discussion.text = current.isEmpty ? words : '$current $words';
              _discussion.selection = TextSelection.collapsed(
                offset: _discussion.text.length,
              );
              widget.controller.update(
                (item) =>
                    item.copyWith(teamMeetingDiscussion: _discussion.text),
              );
            },
          ),
        ),
      ],
    );
  }
}
