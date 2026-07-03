import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';

class VisitHeaderStep extends StatelessWidget {
  const VisitHeaderStep({super.key, required this.controller});

  final VisitAssessmentController controller;

  @override
  Widget build(BuildContext context) {
    final assessment = controller.assessment;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const AssessmentSectionTitle('Visit Information'),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AssessmentLabel('Patient'),
                  AssessmentTextField(
                    initialValue: assessment.patientName,
                    readOnly: true,
                    suffixIcon: const Icon(Icons.person_outline, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AssessmentLabel('Age'),
                  AssessmentTextField(
                    initialValue: assessment.patientAge,
                    onChanged: (value) => controller.update(
                      (item) => item.copyWith(patientAge: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AssessmentLabel('Reg No.', required: true),
                  AssessmentTextField(
                    initialValue: assessment.regNo,
                    onChanged: (value) => controller.update(
                      (item) => item.copyWith(regNo: value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const AssessmentLabel('Visit Date', required: true),
        AssessmentTextField(
          initialValue: DateFormat('dd MMM yyyy').format(assessment.visitDate),
          readOnly: true,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 17),
          onTap: () => _pickDate(context),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _timeField(context, 'Time From', true)),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 21, 12, 0),
              child: Icon(Icons.arrow_forward, size: 18),
            ),
            Expanded(child: _timeField(context, 'Time To', false)),
          ],
        ),
        const SizedBox(height: 14),
        const AssessmentLabel('Team', required: true),
        AssessmentTextField(
          initialValue: assessment.team.isEmpty
              ? 'Team Oruma'
              : assessment.team,
          hint: 'Enter team name',
          suffixIcon: const Icon(Icons.groups_outlined, size: 18),
          onChanged: (value) =>
              controller.update((item) => item.copyWith(team: value)),
        ),
        const SizedBox(height: 17),
        const AssessmentLabel('Visit Type'),
        AssessmentSegment(
          options: const ['NHC', 'DHC', 'GVHC', 'other'],
          selected: assessment.visitType,
          labels: const {'other': 'Other'},
          onSelected: (value) =>
              controller.update((item) => item.copyWith(visitType: value)),
        ),
      ],
    );
  }

  Widget _timeField(BuildContext context, String label, bool from) {
    final value = from
        ? controller.assessment.timeFrom
        : controller.assessment.timeTo;
    final parsed = _parseTime(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssessmentLabel(label, required: true),
        AssessmentTextField(
          key: ValueKey('visit-time-$from-$value'),
          initialValue: parsed == null ? value : parsed.format(context),
          readOnly: true,
          suffixIcon: const Icon(Icons.access_time, size: 17),
          onTap: () => _pickTime(context, from, parsed),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.assessment.visitDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.update((item) => item.copyWith(visitDate: picked));
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    bool from,
    TimeOfDay? current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    controller.update(
      (item) =>
          from ? item.copyWith(timeFrom: value) : item.copyWith(timeTo: value),
    );
  }

  TimeOfDay? _parseTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(':');
    if (parts.length != 2) return _parseDisplayTime(trimmed);
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return _parseDisplayTime(trimmed);
    return TimeOfDay(hour: hour, minute: minute);
  }

  TimeOfDay? _parseDisplayTime(String value) {
    try {
      final parsed = DateFormat.jm().parse(value);
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      return null;
    }
  }
}
