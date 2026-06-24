import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oruma_app/features/visit_assessment/data/assessment_media_service.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';

class PhysicalExamStep extends StatelessWidget {
  const PhysicalExamStep({super.key, required this.controller});

  final VisitAssessmentController controller;

  static const _primaryEnglish = <String, String>{
    'respiration': 'Respiration',
    'foodWater': 'Food & Water Intake',
    'urine': 'Urine',
    'defecation': 'Defecation',
    'sleep': 'Sleep',
    'hygiene': 'Hygiene',
    'outdoorAccess': 'Outdoor Access',
    'sexuality': 'Sexuality',
  };

  static const _primaryMalayalam = <String, String>{
    'respiration': 'ശ്വസനം',
    'foodWater': 'അന്നപാനീയങ്ങൾ',
    'urine': 'മൂത്രം',
    'defecation': 'ശോധന',
    'sleep': 'ഉറക്കം',
    'hygiene': 'ശുചിത്വം (ശരീരം, പരിസരം)',
    'outdoorAccess': 'ഔട്ട് ഡോർ അവേഴ്സ്, വ്യായാമം',
    'sexuality': 'ലൈംഗികത',
  };

  static const _headToFootEnglish = <String, String>{
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

  static const _headToFootMalayalam = <String, String>{
    'scalpHair': 'സ്കാൽപ്പ്, മുടി',
    'skin': 'തൊലി',
    'eyeNoseMouth': 'കണ്ണ്, മുഖ്, ചെവി',
    'oral': 'വായ (പല്ല്, നാവ്, നാസി, അണ്ണാക്ക്, തൊണ്ട etc...)',
    'nails': 'നഖം',
    'perineum': 'പെരിനിയം',
    'pressureArea': 'പ്രഷർ ഏരിയ',
    'hiddenArea': 'ഹിഡൻ ഏരിയ',
    'musclesJoints': 'പേശി - സന്ധികൾ',
    'specialAttention': 'പ്രത്യേക ശ്രദ്ധ പതിയേണ്ട ഭാഗങ്ങൾ :',
  };

  static const _previousVisitPromptEnglish =
      "The difficulties/problems noted during the previous visit and their current status, the patient's main complaints / major difficulties / general condition.";

  static const _previousVisitPromptMalayalam =
      'കഴിഞ്ഞ സന്ദർശനത്തിലെഴുതിയിരുന്ന ബുദ്ധിമുട്ടുകളും അതിന്റെ ഇപ്പോഴത്തെ അവസ്ഥയും, രോഗിയുടെ പ്രധാന പരാതികൾ / പ്രധാന ബുദ്ധിമുട്ട് / പൊതു അവസ്ഥ';

  @override
  Widget build(BuildContext context) {
    final isMalayalam = controller.isMalayalam;
    final primary = isMalayalam ? _primaryMalayalam : _primaryEnglish;
    final headToFoot = isMalayalam ? _headToFootMalayalam : _headToFootEnglish;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AssessmentSectionTitle(
          isMalayalam ? 'ശാരീരിക പരിശോധന' : 'Physical Examination',
        ),
        const SizedBox(height: 12),
        AssessmentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMalayalam
                    ? _previousVisitPromptMalayalam
                    : _previousVisitPromptEnglish,
                style: const TextStyle(
                  color: assessmentText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              AssessmentTextField(
                key: const ValueKey('previous-visit-concerns'),
                initialValue: controller.assessment.previousVisitConcerns,
                hint: isMalayalam
                    ? 'വിശദാംശങ്ങൾ രേഖപ്പെടുത്തുക'
                    : 'Enter the current status and main concerns',
                minLines: 4,
                maxLines: 7,
                onChanged: (value) => controller.update(
                  (assessment) =>
                      assessment.copyWith(previousVisitConcerns: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        _group(
          context,
          title: isMalayalam ? 'പ്രാഥമിക കാര്യങ്ങൾ' : 'Primary Functions',
          items: primary,
          isMalayalam: isMalayalam,
          initiallyExpanded: true,
        ),
        const SizedBox(height: 9),
        _group(
          context,
          title: isMalayalam
              ? 'ഹെഡ് ടു ഫൂട്ട് പരിശോധന'
              : 'Head to Foot Examination',
          items: headToFoot,
          isMalayalam: isMalayalam,
        ),
      ],
    );
  }

  Widget _group(
    BuildContext context, {
    required String title,
    required Map<String, String> items,
    required bool isMalayalam,
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
                '${items.length} ${isMalayalam ? 'ഇനങ്ങൾ' : 'items'}',
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
                    .map(
                      (entry) => _finding(
                        context,
                        entry.key,
                        entry.value,
                        isMalayalam,
                      ),
                    )
                    .toList(),
        ),
      ),
    );
  }

  Widget _finding(
    BuildContext context,
    String key,
    String label,
    bool isMalayalam,
  ) {
    final finding =
        controller.assessment.physicalExam[key] ?? const ExamFinding();
    final options = _findingOptions(key, isMalayalam);
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
    final statusText = selectedOption.isNotEmpty
        ? options.$2[selectedOption] ?? finding.value
        : finding.value.isNotEmpty
        ? finding.value
        : finding.status == 'not_assessed'
        ? isMalayalam
              ? 'പരിശോധിച്ചിട്ടില്ല'
              : 'Not assessed'
        : finding.status == 'normal'
        ? isMalayalam
              ? 'സാധാരണം'
              : 'Normal'
        : isMalayalam
        ? 'അസാധാരണം'
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
                  value: selection,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AssessmentTextField(
              key: ValueKey('physical-exam-notes-$key'),
              initialValue: finding.notes,
              hint: isMalayalam
                  ? 'ആവശ്യമെങ്കിൽ ക്ലിനിക്കൽ നിരീക്ഷണം'
                  : 'Optional clinical observation',
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
                  Expanded(
                    child: AssessmentLabel(isMalayalam ? 'ഫോട്ടോ' : 'Photo'),
                  ),
                  IconButton(
                    onPressed: () => _pickImage(context, key, isMalayalam),
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

  Future<void> _pickImage(
    BuildContext context,
    String key,
    bool isMalayalam,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(isMalayalam ? 'ഫോട്ടോ എടുക്കുക' : 'Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                isMalayalam
                    ? 'ഗാലറിയിൽ നിന്ന് തിരഞ്ഞെടുക്കുക'
                    : 'Choose from gallery',
              ),
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

  (List<String>, Map<String, String>) _findingOptions(
    String key,
    bool isMalayalam,
  ) {
    switch (key) {
      case 'foodWater':
        return (
          const ['good', 'reduced', 'poor'],
          isMalayalam
              ? const {'good': 'നല്ലത്', 'reduced': 'കുറഞ്ഞത്', 'poor': 'മോശം'}
              : const {'good': 'Good', 'reduced': 'Reduced', 'poor': 'Poor'},
        );
      case 'urine':
        return (
          const ['normal', 'retention', 'catheter', 'incontinence'],
          isMalayalam
              ? const {
                  'normal': 'സാധാരണം',
                  'retention': 'തടസ്സം',
                  'catheter': 'കാത്തീറ്റർ',
                  'incontinence': 'നിയന്ത്രണമില്ലായ്മ',
                }
              : const {
                  'normal': 'Normal',
                  'retention': 'Retention',
                  'catheter': 'Catheter',
                  'incontinence': 'Incontinence',
                },
        );
      case 'defecation':
        return (
          const ['normal', 'constipation', 'diarrhea', 'incontinence'],
          isMalayalam
              ? const {
                  'normal': 'സാധാരണം',
                  'constipation': 'മലബന്ധം',
                  'diarrhea': 'വയറിളക്കം',
                  'incontinence': 'നിയന്ത്രണമില്ലായ്മ',
                }
              : const {
                  'normal': 'Normal',
                  'constipation': 'Constipation',
                  'diarrhea': 'Diarrhea',
                  'incontinence': 'Incontinence',
                },
        );
      case 'sleep':
        return (
          const ['good', 'disturbed', 'insomnia'],
          isMalayalam
              ? const {
                  'good': 'നല്ലത്',
                  'disturbed': 'തടസ്സപ്പെട്ടത്',
                  'insomnia': 'ഉറക്കമില്ലായ്മ',
                }
              : const {
                  'good': 'Good',
                  'disturbed': 'Disturbed',
                  'insomnia': 'Insomnia',
                },
        );
      case 'hygiene':
        return (
          const ['good', 'fair', 'poor'],
          isMalayalam
              ? const {'good': 'നല്ലത്', 'fair': 'ശരാശരി', 'poor': 'മോശം'}
              : const {'good': 'Good', 'fair': 'Fair', 'poor': 'Poor'},
        );
      case 'outdoorAccess':
        return (
          const ['yes', 'limited', 'no'],
          isMalayalam
              ? const {'yes': 'ഉണ്ട്', 'limited': 'പരിമിതം', 'no': 'ഇല്ല'}
              : const {'yes': 'Yes', 'limited': 'Limited', 'no': 'No'},
        );
      default:
        return (
          const ['normal', 'abnormal'],
          isMalayalam
              ? const {'normal': 'സാധാരണം', 'abnormal': 'അസാധാരണം'}
              : const {'normal': 'Normal', 'abnormal': 'Abnormal'},
        );
    }
  }
}
