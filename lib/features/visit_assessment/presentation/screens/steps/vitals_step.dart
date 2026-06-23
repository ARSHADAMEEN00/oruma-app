import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';

class VitalsStep extends StatelessWidget {
  const VitalsStep({super.key, required this.controller});

  final VisitAssessmentController controller;

  @override
  Widget build(BuildContext context) {
    final vitals = controller.assessment.vitals;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const AssessmentSectionTitle('Vitals'),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: _number(
                'Pulse (/min)',
                vitals.pulse,
                (value) => controller.updateVitals(
                  (vitals) => vitals.copyWith(
                    pulse: int.tryParse(value),
                    clearPulse: value.isEmpty,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _segment(
                'Rhythm',
                const ['R', 'IR'],
                vitals.pulseRhythm,
                const {'R': 'Regular', 'IR': 'Irregular'},
                (value) => controller.updateVitals(
                  (vitals) => vitals.copyWith(pulseRhythm: value),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _bloodPressure(vitals)),
            const SizedBox(width: 10),
            Expanded(
              child: _segment(
                'Position',
                const ['UL', 'LL', 'Rt', 'Lt'],
                vitals.bpPosition,
                const {},
                (value) => controller.updateVitals(
                  (vitals) => vitals.copyWith(bpPosition: value),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _number(
                'RR (/min)',
                vitals.respiratoryRate,
                (value) => controller.updateVitals(
                  (vitals) => vitals.copyWith(
                    respiratoryRate: int.tryParse(value),
                    clearRespiratoryRate: value.isEmpty,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AssessmentLabel('Temperature'),
                  Row(
                    children: [
                      Expanded(
                        child: _numericField(
                          vitals.temperature?.toString() ?? '',
                          (value) => controller.updateVitals(
                            (vitals) => vitals.copyWith(
                              temperature: double.tryParse(value),
                              clearTemperature: value.isEmpty,
                            ),
                          ),
                          decimal: true,
                        ),
                      ),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 86,
                        child: AssessmentSegment(
                          compact: true,
                          options: const ['C', 'F'],
                          labels: const {'C': '°C', 'F': '°F'},
                          selected: vitals.temperatureUnit,
                          onSelected: (value) => controller.updateVitals(
                            (vitals) => vitals.copyWith(temperatureUnit: value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _segment(
          'Method',
          const ['O', 'A', 'R'],
          vitals.temperatureMethod,
          const {'O': 'Oral', 'A': 'Axillary', 'R': 'Rectal'},
          (value) => controller.updateVitals(
            (vitals) => vitals.copyWith(temperatureMethod: value),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _number(
                'SpO₂ (%)',
                vitals.spo2,
                (value) => controller.updateVitals(
                  (vitals) => vitals.copyWith(
                    spo2: int.tryParse(value),
                    clearSpo2: value.isEmpty,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _number(
                'GRBS (mg/dl)',
                vitals.grbs,
                (value) => controller.updateVitals(
                  (vitals) => vitals.copyWith(
                    grbs: int.tryParse(value),
                    clearGrbs: value.isEmpty,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _segment(
          'Activity Level',
          const ['I', 'II', 'III', 'IV', 'V'],
          vitals.activityLevel,
          const {},
          (value) => controller.updateVitals(
            (vitals) => vitals.copyWith(activityLevel: value),
          ),
        ),
        const SizedBox(height: 12),
        _segment(
          'Stability',
          const ['stable', 'unstable'],
          vitals.stability,
          const {'stable': '◉ Stable', 'unstable': '◉ Unstable'},
          (value) => controller.updateVitals(
            (vitals) => vitals.copyWith(stability: value),
          ),
          dangerValue: 'unstable',
        ),
      ],
    );
  }

  Widget _number(String label, num? value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssessmentLabel(label),
        _numericField(value?.toString() ?? '', onChanged),
      ],
    );
  }

  Widget _numericField(
    String value,
    ValueChanged<String> onChanged, {
    bool decimal = false,
  }) {
    return TextFormField(
      key: ValueKey('$value-$decimal'),
      initialValue: value,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'^\d{0,3}\.?\d{0,2}') : RegExp(r'^\d{0,4}'),
        ),
      ],
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: assessmentBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: assessmentBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: assessmentGreen),
        ),
      ),
    );
  }

  Widget _bloodPressure(VisitVitals vitals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AssessmentLabel('BP (mmHg)'),
        Row(
          children: [
            Expanded(
              child: _numericField(
                vitals.bpSystolic?.toString() ?? '',
                (value) => controller.updateVitals(
                  (vitals) => vitals.copyWith(
                    bpSystolic: int.tryParse(value),
                    clearBpSystolic: value.isEmpty,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('/', style: TextStyle(color: assessmentMuted)),
            ),
            Expanded(
              child: _numericField(
                vitals.bpDiastolic?.toString() ?? '',
                (value) => controller.updateVitals(
                  (vitals) => vitals.copyWith(
                    bpDiastolic: int.tryParse(value),
                    clearBpDiastolic: value.isEmpty,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _segment(
    String label,
    List<String> options,
    String selected,
    Map<String, String> labels,
    ValueChanged<String> onSelected, {
    String? dangerValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssessmentLabel(label),
        AssessmentSegment(
          options: options,
          selected: selected,
          labels: labels,
          dangerValue: dangerValue,
          onSelected: onSelected,
          compact: true,
        ),
      ],
    );
  }
}
