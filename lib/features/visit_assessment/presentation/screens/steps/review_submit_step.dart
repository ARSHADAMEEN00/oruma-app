import 'package:flutter/material.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';

class ReviewSubmitStep extends StatefulWidget {
  const ReviewSubmitStep({super.key, required this.controller});

  final VisitAssessmentController controller;

  @override
  State<ReviewSubmitStep> createState() => _ReviewSubmitStepState();
}

class _ReviewSubmitStepState extends State<ReviewSubmitStep> {
  late final TextEditingController _nurseName;

  @override
  void initState() {
    super.initState();
    _nurseName = TextEditingController(
      text: widget.controller.assessment.nurseName,
    );
  }

  @override
  void dispose() {
    _nurseName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assessment = widget.controller.assessment;
    final sections = <(String, int)>[
      ('Visit Information', 0),
      ('Physical Examination', 1),
      ('Vitals', 2),
      ('Medicines (${assessment.medicines.length})', 3),
      ('Clinical Notes', 4),
      ('Care Plan', 5),
      ('Team Discussion', 5),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const AssessmentSectionTitle('Review & Submit'),
        const SizedBox(height: 12),
        ...sections.map((section) {
          final complete = widget.controller.validateStep(section.$2) == null;
          return InkWell(
            onTap: () => widget.controller.setStep(section.$2),
            borderRadius: BorderRadius.circular(7),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    complete ? Icons.check_circle : Icons.error_outline_rounded,
                    color: complete ? assessmentGreen : const Color(0xFFE48B16),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      section.$1,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: assessmentMuted,
                  ),
                ],
              ),
            ),
          );
        }),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 9),
          child: Divider(color: assessmentBorder),
        ),
        Row(
          children: [
            const Text(
              'Nurse',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _editNurse(context),
              style: TextButton.styleFrom(
                foregroundColor: assessmentGreenDark,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Change', style: TextStyle(fontSize: 9)),
            ),
          ],
        ),
        Text(
          assessment.nurseName.isEmpty ? 'Not selected' : assessment.nurseName,
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 13),
        InkWell(
          onTap: () => widget.controller.update(
            (item) => item.copyWith(confirmed: !item.confirmed),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: assessment.confirmed
                        ? assessmentGreen
                        : Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: assessment.confirmed
                          ? assessmentGreen
                          : assessmentBorder,
                    ),
                  ),
                  child: assessment.confirmed
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'I confirm all information is correct.',
                    style: TextStyle(fontSize: 10, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.controller.syncMessage?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  widget.controller.syncState == AssessmentSyncState.error ||
                      widget.controller.syncState == AssessmentSyncState.offline
                  ? const Color(0xFFFFF4E6)
                  : assessmentMint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.controller.syncMessage!,
              style: const TextStyle(fontSize: 10, color: assessmentMuted),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _editNurse(BuildContext context) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nurse name'),
        content: TextField(
          controller: _nurseName,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter nurse name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _nurseName.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: assessmentGreen),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value?.isNotEmpty == true) {
      widget.controller.update((item) => item.copyWith(nurseName: value));
    }
  }
}
