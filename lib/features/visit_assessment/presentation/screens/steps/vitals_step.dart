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
    controller.ensureVitalDefaults();
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
                'pulse',
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
                'respiratory-rate',
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
              child: _segment(
                'RR Rhythm',
                const ['R', 'IR'],
                vitals.respiratoryRhythm,
                const {'R': 'Regular', 'IR': 'Irregular'},
                (value) => controller.updateVitals(
                  (vitals) => vitals.copyWith(respiratoryRhythm: value),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const AssessmentLabel('Temperature'),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _numericField(
                'temperature',
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
            const SizedBox(width: 7),
            Expanded(
              flex: 2,
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
            const SizedBox(width: 7),
            Expanded(flex: 3, child: _temperatureMethod(vitals)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _number(
                'spo2',
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
                'grbs',
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
        const AssessmentLabel('Patient Stability'),
        _stabilityChecks(vitals),
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
      ],
    );
  }

  Widget _number(
    String fieldId,
    String label,
    num? value,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssessmentLabel(label),
        _numericField(fieldId, value?.toString() ?? '', onChanged),
      ],
    );
  }

  Widget _numericField(
    String fieldId,
    String value,
    ValueChanged<String> onChanged, {
    bool decimal = false,
  }) {
    return TextFormField(
      key: ValueKey('vitals-defaults-v2-$fieldId'),
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
                'bp-systolic',
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
                'bp-diastolic',
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

  Widget _temperatureMethod(VisitVitals vitals) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: 'O', label: Text('O'), tooltip: 'Oral'),
        ButtonSegment(value: 'A', label: Text('A'), tooltip: 'Axillary'),
        ButtonSegment(value: 'R', label: Text('R'), tooltip: 'Rectal'),
      ],
      selected: {vitals.temperatureMethod},
      onSelectionChanged: (selected) => controller.updateVitals(
        (value) => value.copyWith(temperatureMethod: selected.first),
      ),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 5),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? assessmentGreen
                : assessmentBorder,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? assessmentMint
              : Colors.white,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? assessmentGreenDark
              : assessmentText,
        ),
        textStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _stabilityChecks(VisitVitals vitals) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _stabilityCheck(
            label: 'Stable',
            selected: vitals.stability == 'stable',
            onTap: () => controller.updateVitals(
              (value) => value.copyWith(stability: 'stable'),
            ),
          ),
          const SizedBox(width: 24),
          _stabilityCheck(
            label: 'Unstable',
            selected: vitals.stability == 'unstable',
            danger: true,
            onTap: () => controller.updateVitals(
              (value) => value.copyWith(stability: 'unstable'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stabilityCheck({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final selectedColor = danger ? assessmentDanger : assessmentGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? selectedColor : assessmentText,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? selectedColor : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected ? selectedColor : assessmentMuted,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
