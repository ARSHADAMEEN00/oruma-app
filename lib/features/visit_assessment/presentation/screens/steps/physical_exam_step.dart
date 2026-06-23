import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oruma_app/features/visit_assessment/data/assessment_media_service.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';

class PhysicalExamStep extends StatelessWidget {
  const PhysicalExamStep({super.key, required this.controller});

  final VisitAssessmentController controller;

  static const _primary = <String, String>{
    'respiration': 'Respiration',
    'foodWater': 'Food & Water Intake',
    'urine': 'Urine',
    'defecation': 'Defecation',
    'sleep': 'Sleep',
    'hygiene': 'Hygiene',
    'outdoorAccess': 'Outdoor Access',
    'sexuality': 'Sexuality',
  };

  static const _headToFoot = <String, String>{
    'scalpHair': 'Scalp & Hair',
    'skin': 'Skin',
    'eyeNoseMouth': 'Eye, Nose, Ear',
    'oral': 'Oral',
    'nails': 'Nails',
    'perineum': 'Perineum',
    'pressureArea': 'Pressure Area',
    'hiddenArea': 'Hidden Area',
    'musclesJoints': 'Muscles & Joints',
    'specialAttention': 'Special Attention',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const AssessmentSectionTitle('Physical Examination'),
        const SizedBox(height: 12),
        _group(
          context,
          title: 'Primary Functions',
          items: _primary,
          initiallyExpanded: true,
        ),
        const SizedBox(height: 9),
        _group(context, title: 'Head to Foot Examination', items: _headToFoot),
        const SizedBox(height: 9),
        _group(
          context,
          title: 'Additional Observations',
          items: const {},
          emptyMessage: 'No additional observations added',
        ),
      ],
    );
  }

  Widget _group(
    BuildContext context, {
    required String title,
    required Map<String, String> items,
    bool initiallyExpanded = false,
    String? emptyMessage,
  }) {
    return AssessmentCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 13),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(
            Icons.chevron_right,
            size: 17,
            color: assessmentMuted,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${items.length} items',
                style: const TextStyle(color: assessmentMuted, fontSize: 9),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: assessmentMuted,
              ),
            ],
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          children: items.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      emptyMessage ?? '',
                      style: const TextStyle(
                        color: assessmentMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ]
              : items.entries
                    .map((entry) => _finding(context, entry.key, entry.value))
                    .toList(),
        ),
      ),
    );
  }

  Widget _finding(BuildContext context, String key, String label) {
    final finding =
        controller.assessment.physicalExam[key] ?? const ExamFinding();
    final options = _findingOptions(key);
    final normalizedValue = finding.value.toLowerCase().replaceAll(' ', '_');
    final selectedOption = options.$1.contains(normalizedValue)
        ? normalizedValue
        : options.$1.contains(finding.status)
        ? finding.status
        : '';
    final statusColor = finding.status == 'abnormal'
        ? assessmentDanger
        : finding.status == 'normal'
        ? assessmentGreen
        : assessmentMuted;
    final statusText = finding.value.isNotEmpty
        ? finding.value
        : finding.status == 'not_assessed'
        ? 'Not assessed'
        : finding.status == 'normal'
        ? 'Normal'
        : 'Abnormal';
    final imageEnabled = const {
      'skin',
      'pressureArea',
      'specialAttention',
    }.contains(key);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: assessmentBorder),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 11),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 11),
          title: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 7),
              const Icon(Icons.keyboard_arrow_down, size: 17),
            ],
          ),
          children: [
            AssessmentSegment(
              compact: true,
              options: options.$1,
              labels: options.$2,
              selected: selectedOption,
              dangerValue: options.$1.length == 2 ? 'abnormal' : null,
              onSelected: (selection) => controller.updateFinding(
                key,
                (value) => value.copyWith(
                  status: selection == options.$1.first ? 'normal' : 'abnormal',
                  value: options.$2[selection] ?? selection,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: AssessmentLabel('Notes'),
            ),
            AssessmentTextField(
              key: ValueKey('$key-${finding.notes}'),
              initialValue: finding.notes,
              hint: 'Optional clinical observation',
              minLines: 2,
              maxLines: 3,
              onChanged: (notes) => controller.updateFinding(
                key,
                (value) => value.copyWith(notes: notes),
              ),
            ),
            if (imageEnabled) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(child: AssessmentLabel('Photo')),
                  IconButton(
                    onPressed: () => _pickImage(context, key),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.add_a_photo_outlined,
                      color: assessmentGreenDark,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (finding.images.isNotEmpty)
                SizedBox(
                  height: 68,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: finding.images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 7),
                    itemBuilder: (context, index) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: SizedBox(
                            width: 68,
                            height: 68,
                            child: AssessmentDataImage(
                              dataUrl: finding.images[index],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () {
                              final images = [...finding.images]
                                ..removeAt(index);
                              controller.updateFinding(
                                key,
                                (value) => value.copyWith(images: images),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, String key) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await AssessmentMediaService.pickCompressedImage(source);
    if (image == null) return;
    final current =
        controller.assessment.physicalExam[key] ?? const ExamFinding();
    controller.updateFinding(
      key,
      (value) => value.copyWith(images: [...current.images, image]),
    );
  }

  (List<String>, Map<String, String>) _findingOptions(String key) {
    switch (key) {
      case 'foodWater':
        return (
          const ['good', 'reduced', 'poor'],
          const {'good': 'Good', 'reduced': 'Reduced', 'poor': 'Poor'},
        );
      case 'urine':
        return (
          const ['normal', 'retention', 'catheter', 'incontinence'],
          const {
            'normal': 'Normal',
            'retention': 'Retention',
            'catheter': 'Catheter',
            'incontinence': 'Incontinence',
          },
        );
      case 'defecation':
        return (
          const ['normal', 'constipation', 'diarrhea', 'incontinence'],
          const {
            'normal': 'Normal',
            'constipation': 'Constipation',
            'diarrhea': 'Diarrhea',
            'incontinence': 'Incontinence',
          },
        );
      case 'sleep':
        return (
          const ['good', 'disturbed', 'insomnia'],
          const {
            'good': 'Good',
            'disturbed': 'Disturbed',
            'insomnia': 'Insomnia',
          },
        );
      case 'hygiene':
        return (
          const ['good', 'fair', 'poor'],
          const {'good': 'Good', 'fair': 'Fair', 'poor': 'Poor'},
        );
      case 'outdoorAccess':
        return (
          const ['yes', 'limited', 'no'],
          const {'yes': 'Yes', 'limited': 'Limited', 'no': 'No'},
        );
      default:
        return (
          const ['normal', 'abnormal'],
          const {'normal': 'Normal', 'abnormal': 'Abnormal'},
        );
    }
  }
}
