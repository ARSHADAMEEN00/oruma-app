import 'package:flutter/material.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';
import 'package:oruma_app/models/medicine.dart';
import 'package:oruma_app/services/medicine_service.dart';

class MedicinesStep extends StatelessWidget {
  const MedicinesStep({super.key, required this.controller});

  final VisitAssessmentController controller;

  @override
  Widget build(BuildContext context) {
    final assessment = controller.assessment;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      children: [
        AssessmentSectionTitle(
          'Medicines',
          trailing: OutlinedButton.icon(
            onPressed: () => _showEditor(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Medicine'),
            style: OutlinedButton.styleFrom(
              foregroundColor: assessmentGreenDark,
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: Color(0xFFBBDDCF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        if (controller.previousAssessments.any(
          (item) => item.medicines.isNotEmpty,
        )) ...[
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: controller.copyMedicinesFromPrevious,
              icon: const Icon(Icons.copy_all_outlined, size: 15),
              label: const Text('Copy previous medicines'),
              style: TextButton.styleFrom(
                foregroundColor: assessmentGreenDark,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (assessment.medicines.isEmpty)
          const AssessmentEmptyState(
            icon: Icons.medication_outlined,
            title: 'No medicines added',
            message:
                'Add the medicines the patient is currently taking, or copy them from the previous assessment.',
          )
        else
          ...List.generate(
            assessment.medicines.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _medicineCard(context, assessment.medicines[index], index),
            ),
          ),
        const SizedBox(height: 10),
        const AssessmentLabel('Complementary Medicine'),
        AssessmentSegment(
          compact: true,
          options: const ['Nil', 'Ay', 'H', 'U', 'Sd', 'N', 'O'],
          labels: const {
            'Ay': 'Ayurveda',
            'H': 'Homeopathy',
            'U': 'Unani',
            'Sd': 'Siddha',
            'N': 'Naturopathy',
            'O': 'Other',
          },
          selected: assessment.complementary,
          onSelected: (value) =>
              controller.update((item) => item.copyWith(complementary: value)),
        ),
      ],
    );
  }

  Widget _medicineCard(
    BuildContext context,
    AssessmentMedicine medicine,
    int index,
  ) {
    return AssessmentCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.medicineName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (medicine.strength.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        medicine.strength,
                        style: const TextStyle(
                          color: assessmentMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    _showEditor(context, existing: medicine, index: index),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 16),
              ),
              IconButton(
                onPressed: () => controller.removeMedicine(index),
                visualDensity: VisualDensity.compact,
                color: assessmentDanger,
                icon: const Icon(Icons.delete_outline, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Route',
            style: TextStyle(fontSize: 9, color: assessmentMuted),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 14,
            children: ['P', 'G', 'S', 'O'].map((route) {
              final active = medicine.routes.contains(route);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: active ? assessmentGreen : Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: active ? assessmentGreen : assessmentBorder,
                      ),
                    ),
                    child: active
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 5),
                  Text(route, style: const TextStyle(fontSize: 9)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _valueBox('Duration', medicine.duration)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _valueBox('Remarks', medicine.remarks)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valueBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: assessmentMuted),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: assessmentBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditor(
    BuildContext context, {
    AssessmentMedicine? existing,
    int? index,
  }) async {
    final value = await showModalBottomSheet<AssessmentMedicine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MedicineEditorSheet(existing: existing),
    );
    if (value == null) return;
    if (index == null) {
      controller.addMedicine(value);
    } else {
      controller.replaceMedicine(index, value);
    }
  }
}

class _MedicineEditorSheet extends StatefulWidget {
  const _MedicineEditorSheet({this.existing});

  final AssessmentMedicine? existing;

  @override
  State<_MedicineEditorSheet> createState() => _MedicineEditorSheetState();
}

class _MedicineEditorSheetState extends State<_MedicineEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _strength;
  late final TextEditingController _duration;
  late final TextEditingController _remarks;
  late Set<String> _routes;
  String? _medicineId;
  List<Medicine> _medicines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final value = widget.existing;
    _name = TextEditingController(text: value?.medicineName ?? '');
    _strength = TextEditingController(text: value?.strength ?? '');
    _duration = TextEditingController(text: value?.duration ?? '');
    _remarks = TextEditingController(text: value?.remarks ?? '');
    _routes = {...?value?.routes};
    if (_routes.isEmpty) _routes.add('P');
    _medicineId = value?.medicineId;
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      final values = await MedicineService.getMedicines();
      if (mounted) {
        setState(() {
          _medicines = values;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _strength.dispose();
    _duration.dispose();
    _remarks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: assessmentBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.existing == null ? 'Add Medicine' : 'Edit Medicine',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const AssessmentLabel('Search Medicine', required: true),
                if (_loading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: assessmentGreen,
                  )
                else
                  Autocomplete<Medicine>(
                    initialValue: TextEditingValue(text: _name.text),
                    displayStringForOption: (option) => option.name,
                    optionsBuilder: (value) {
                      final query = value.text.trim().toLowerCase();
                      if (query.isEmpty) return _medicines.take(20);
                      return _medicines.where(
                        (item) =>
                            item.name.toLowerCase().contains(query) ||
                            item.code.toLowerCase().contains(query) ||
                            item.brandNames.any(
                              (brand) => brand.toLowerCase().contains(query),
                            ),
                      );
                    },
                    onSelected: (medicine) {
                      _medicineId = medicine.id;
                      _name.text = medicine.name;
                      if (_strength.text.isEmpty && medicine.strength != null) {
                        final number = medicine.strength!;
                        _strength.text =
                            '${number == number.roundToDouble() ? number.toInt() : number}${medicine.strengthUnit ?? ''}';
                      }
                    },
                    fieldViewBuilder:
                        (context, textController, focusNode, onSubmitted) {
                          if (textController.text != _name.text) {
                            textController.text = _name.text;
                          }
                          textController.addListener(() {
                            if (_name.text != textController.text) {
                              _name.text = textController.text;
                              _medicineId = null;
                            }
                          });
                          return TextFormField(
                            controller: textController,
                            focusNode: focusNode,
                            validator: (value) => value?.trim().isEmpty != false
                                ? 'Medicine name is required'
                                : null,
                            decoration: _decoration('Type medicine name'),
                          );
                        },
                  ),
                if (_medicines.isEmpty && !_loading) ...[
                  const SizedBox(height: 8),
                  AssessmentTextField(
                    controller: _name,
                    hint: 'Enter medicine name',
                  ),
                ],
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AssessmentLabel('Strength'),
                          AssessmentTextField(
                            controller: _strength,
                            hint: 'e.g. 500 mg',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AssessmentLabel('Duration'),
                          AssessmentTextField(
                            controller: _duration,
                            hint: 'e.g. 7 days',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                const AssessmentLabel('Route'),
                AssessmentMultiSegment(
                  options: const ['P', 'G', 'S', 'O'],
                  selected: _routes,
                  onToggle: (value) {
                    setState(() {
                      _routes.contains(value)
                          ? _routes.remove(value)
                          : _routes.add(value);
                    });
                  },
                ),
                const SizedBox(height: 13),
                const AssessmentLabel('Remarks'),
                AssessmentTextField(
                  controller: _remarks,
                  hint: 'Dose timing or special instruction',
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: assessmentGreen,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Text(
                    widget.existing == null ? 'Add Medicine' : 'Save Changes',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: assessmentBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: assessmentBorder),
    ),
  );

  void _save() {
    if (!_formKey.currentState!.validate() || _name.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      AssessmentMedicine(
        id: widget.existing?.id,
        medicineId: _medicineId,
        medicineName: _name.text.trim(),
        strength: _strength.text.trim(),
        routes: _routes,
        duration: _duration.text.trim(),
        remarks: _remarks.text.trim(),
      ),
    );
  }
}
