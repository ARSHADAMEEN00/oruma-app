import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';

class CarePlanStep extends StatefulWidget {
  const CarePlanStep({super.key, required this.controller});

  final VisitAssessmentController controller;

  @override
  State<CarePlanStep> createState() => _CarePlanStepState();
}

class _CarePlanStepState extends State<CarePlanStep> {
  static const _visitTypeRows = <(String, String)>[
    ('DHC', 'DHC'),
    ('NHC', 'NHC'),
    ('GVHC', 'GVHC'),
    ('other', 'Other'),
  ];

  late final Map<String, TextEditingController> _visitPlanNotes;
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
    final carePlan = widget.controller.assessment.carePlan;
    _visitPlanNotes = {
      for (final row in _visitTypeRows)
        row.$1: TextEditingController(
          text: carePlan.visitPlanNotes[row.$1] ?? '',
        ),
    };
    _discussion = TextEditingController(
      text: widget.controller.assessment.teamMeetingDiscussion,
    );
  }

  @override
  void dispose() {
    for (final controller in _visitPlanNotes.values) {
      controller.dispose();
    }
    _discussion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.controller.assessment.carePlan;
    final isMalayalam = widget.controller.isMalayalam;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      children: [
        const AssessmentSectionTitle('Care Plan'),
        const SizedBox(height: 15),
        const AssessmentLabel('Visit Type Plan', required: true),
        _visitTypePlanTable(),
        const SizedBox(height: 18),
        AssessmentLabel(
          isMalayalam
              ? 'തുടർ പരിചരണത്തിന് ആവശ്യമുള്ളവ ടിക് ചെയ്യുക'
              : 'Services Required',
          required: true,
        ),
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
            localeId: widget.controller.isMalayalam ? 'ml-IN' : null,
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

  Widget _visitTypePlanTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFD9E1E4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Column(
          children: [
            for (var index = 0; index < _visitTypeRows.length; index++)
              _visitTypePlanRow(
                value: _visitTypeRows[index].$1,
                label: _visitTypeRows[index].$2,
                isLast: index == _visitTypeRows.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _visitTypePlanRow({
    required String value,
    required String label,
    required bool isLast,
  }) {
    final controller = _visitPlanNotes[value]!;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFD9E1E4)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: double.infinity,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFA),
              border: Border(right: BorderSide(color: Color(0xFFD9E1E4))),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: assessmentText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              key: ValueKey('care-plan-visit-$value'),
              controller: controller,
              readOnly: true,
              onTap: () => _pickVisitPlanDate(value, controller),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: '$label date',
                hintStyle: const TextStyle(
                  color: Color(0xFFA8B0B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 34,
                  minHeight: 34,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVisitPlanDate(
    String value,
    TextEditingController controller,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final parsed = _parseVisitPlanDate(controller.text);
    final initial = parsed != null && !parsed.isBefore(today) ? parsed : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (picked == null) return;
    final formatted = DateFormat('dd MMM yyyy').format(picked);
    setState(() => controller.text = formatted);
    widget.controller.updateVisitPlanNote(value, formatted);
  }

  DateTime? _parseVisitPlanDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed) ?? _parseDisplayDate(trimmed);
  }

  DateTime? _parseDisplayDate(String value) {
    try {
      return DateFormat('dd MMM yyyy').parseStrict(value);
    } catch (_) {
      return null;
    }
  }
}
