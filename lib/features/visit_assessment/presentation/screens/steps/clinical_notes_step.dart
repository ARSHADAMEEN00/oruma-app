import 'package:flutter/material.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';

class ClinicalNotesStep extends StatefulWidget {
  const ClinicalNotesStep({super.key, required this.controller});

  final VisitAssessmentController controller;

  @override
  State<ClinicalNotesStep> createState() => _ClinicalNotesStepState();
}

class _ClinicalNotesStepState extends State<ClinicalNotesStep> {
  late final TextEditingController _medicineRemarks;
  late final TextEditingController _diagnosis;
  late final TextEditingController _doctorNotes;
  late final TextEditingController _managementPlan;

  @override
  void initState() {
    super.initState();
    final value = widget.controller.assessment;
    _medicineRemarks = TextEditingController(text: value.medicineRemarks);
    _diagnosis = TextEditingController(text: value.nursingDiagnosis);
    _doctorNotes = TextEditingController(text: value.doctorConsultNotes);
    _managementPlan = TextEditingController(text: value.nursingManagementPlan);
  }

  @override
  void dispose() {
    _medicineRemarks.dispose();
    _diagnosis.dispose();
    _doctorNotes.dispose();
    _managementPlan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.controller.isMalayalam;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      children: [
        const AssessmentSectionTitle('Clinical Notes'),
        const SizedBox(height: 14),
        _noteField(
          label: isMalayalam
              ? 'മരുന്ന് സംബന്ധിച്ച് മറ്റു കാര്യങ്ങൾ (മറ്റു ചികിത്സ, മരുന്നറിവ്, ഫലം, ഉപയോഗം Etc )'
              : 'Other matters related to medicine (Other treatment, Medicine knowledge, Effect, Use Etc.) :',
          controller: _medicineRemarks,
          hint: 'Medicine adherence, reactions or special instructions',
          onChanged: (value) => widget.controller.update(
            (item) => item.copyWith(medicineRemarks: value),
          ),
          localeId: isMalayalam ? 'ml-IN' : null,
        ),
        const SizedBox(height: 13),
        _noteField(
          label:
              'Nursing Diagnosis/Doctor Consult/Nursing Management/Medications :',
          required: true,
          controller: _diagnosis,
          hint: 'Current nursing diagnosis',
          onChanged: (value) => widget.controller.update(
            (item) => item.copyWith(nursingDiagnosis: value),
          ),
          localeId: isMalayalam ? 'ml-IN' : null,
        ),
        const SizedBox(height: 13),
        _noteField(
          label: 'Doctor Consult Notes',
          controller: _doctorNotes,
          hint: 'Consultation notes and follow-up',
          onChanged: (value) => widget.controller.update(
            (item) => item.copyWith(doctorConsultNotes: value),
          ),
          localeId: isMalayalam ? 'ml-IN' : null,
        ),
        const SizedBox(height: 13),
        _noteField(
          label: 'Nursing Management Plan',
          controller: _managementPlan,
          hint: 'Care actions, monitoring and repositioning plan',
          onChanged: (value) => widget.controller.update(
            (item) => item.copyWith(nursingManagementPlan: value),
          ),
          localeId: isMalayalam ? 'ml-IN' : null,
        ),
      ],
    );
  }

  Widget _noteField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    bool required = false,
    String? localeId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: AssessmentLabel(label, required: required)),
            AssessmentVoiceButton(
              localeId: localeId,
              label: 'Voice input',
              onWords: (words) {
                final current = controller.text.trim();
                controller.text = current.isEmpty ? words : '$current $words';
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
                onChanged(controller.text);
              },
            ),
          ],
        ),
        AssessmentTextField(
          controller: controller,
          hint: hint,
          minLines: 2,
          maxLines: 4,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
