import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/models/social_support.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/services/social_support_service.dart';

const _supportPrimary = Color(0xFF8A2454);
const _supportDark = Color(0xFF64143A);
const _supportCard = Color(0xFFF7E5EE);
const _supportIcon = Color(0xFFE8AEC9);

class SocialSupportPage extends StatefulWidget {
  final Patient? initialPatient;

  const SocialSupportPage({super.key, this.initialPatient});

  @override
  State<SocialSupportPage> createState() => _SocialSupportPageState();
}

class _SocialSupportPageState extends State<SocialSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _volunteerNameController = TextEditingController();
  final _volunteerContactController = TextEditingController();

  List<Patient> _patients = [];
  Patient? _selectedPatient;
  DateTime _givenAt = DateTime.now();
  bool _loading = true;
  bool _saving = false;

  final Set<String> _selectedTypes = {'ration_kit'};
  final List<String> _supportTypes = const [
    'ration_kit',
    'vegetables',
    'medicine',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.initialPatient;
    _loadPatients();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _volunteerNameController.dispose();
    _volunteerContactController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await PatientService.getAllPatients(isDead: false);
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _givenAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(
        () => _givenAt = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatient?.id == null || _selectedPatient!.id!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a patient')));
      return;
    }

    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one support type'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await SocialSupportService.createSocialSupport(
        SocialSupport(
          patientId: _selectedPatient!.id,
          supportTypes: _selectedTypes.toList(),
          givenAt: _givenAt,
          note: _blankToNull(_noteController.text),
          volunteerName: _volunteerNameController.text.trim(),
          volunteerContact: _volunteerContactController.text.trim(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Social support recorded successfully'),
          backgroundColor: _supportPrimary,
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: _supportDark,
          foregroundColor: Colors.white,
          title: const Text(
            'New Social Support',
            style: TextStyle(fontSize: 18),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _supportPrimary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _supportDark,
        foregroundColor: Colors.white,
        title: const Text('New Social Support', style: TextStyle(fontSize: 18)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: [
            _formHeader(),
            const SizedBox(height: 16),
            _formCard(
              title: 'Patient and date',
              icon: Icons.person_search_outlined,
              children: [
                _patientAutocomplete(),
                if (_selectedPatient != null) _selectedPatientCard(),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: _inputDecoration('Date', Icons.event_outlined),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(_givenAt),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _formCard(
              title: 'Support type',
              icon: Icons.volunteer_activism_outlined,
              children: [_supportTypeSelector()],
            ),
            const SizedBox(height: 14),
            _formCard(
              title: 'Volunteer details',
              icon: Icons.badge_outlined,
              children: [
                _textField(
                  _volunteerNameController,
                  'Volunteer Name',
                  icon: Icons.person_outline,
                  required: true,
                ),
                _textField(
                  _volunteerContactController,
                  'Volunteer Contact',
                  icon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                  required: true,
                ),
                _textField(
                  _noteController,
                  'Note',
                  hint: 'Optional remarks',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _supportPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save Social Support',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _formHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _supportPrimary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(Icons.volunteer_activism_outlined, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Social Support',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _supportDark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _supportPrimary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children.expand(
            (child) => [
              child,
              if (child != children.last) const SizedBox(height: 13),
            ],
          ),
        ],
      ),
    );
  }

  Widget _patientAutocomplete() {
    return Autocomplete<Patient>(
      displayStringForOption: _patientLabel,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<Patient>.empty();
        return _patients.where(
          (patient) =>
              patient.name.toLowerCase().contains(query) ||
              (patient.registerId?.toLowerCase().contains(query) ?? false) ||
              patient.place.toLowerCase().contains(query),
        );
      },
      onSelected: (patient) => setState(() => _selectedPatient = patient),
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        if (_selectedPatient != null && controller.text.isEmpty) {
          controller.text = _patientLabel(_selectedPatient!);
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: _inputDecoration(
            'Patient',
            Icons.person_search_outlined,
            hint: 'Search patient',
          ),
          validator: (_) =>
              _selectedPatient == null ? 'Please select a patient' : null,
        );
      },
    );
  }

  Widget _selectedPatientCard() {
    final patient = _selectedPatient!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _supportCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _supportIcon),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: _supportPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: _supportDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  [
                    if (patient.registerId?.isNotEmpty == true)
                      'Reg No: ${patient.registerId}',
                    if (patient.place.isNotEmpty) 'Place: ${patient.place}',
                    if (patient.phone.isNotEmpty) 'Ph: ${patient.phone}',
                  ].whereType<String>().join(' • '),
                  style: const TextStyle(color: _supportDark, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Clear patient',
            onPressed: () => setState(() => _selectedPatient = null),
            icon: const Icon(Icons.close, color: _supportPrimary),
          ),
        ],
      ),
    );
  }

  Widget _supportTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _supportTypes.map((type) {
        final selected = _selectedTypes.contains(type);
        return FilterChip(
          selected: selected,
          label: Text(socialSupportTypeLabels[type] ?? type),
          avatar: Icon(_supportTypeIcon(type), size: 18),
          selectedColor: _supportIcon,
          checkmarkColor: _supportDark,
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedTypes.add(type);
              } else {
                _selectedTypes.remove(type);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: _inputDecoration(label, icon, hint: hint),
      validator: required
          ? (value) =>
                value?.trim().isEmpty == true ? '$label is required' : null
          : null,
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _supportPrimary, size: 20),
      filled: true,
      fillColor: const Color(0xFFFCF8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _supportPrimary, width: 1.5),
      ),
    );
  }

  IconData _supportTypeIcon(String type) {
    return switch (type) {
      'vegetables' => Icons.eco_outlined,
      'medicine' => Icons.medication_outlined,
      _ => Icons.inventory_2_outlined,
    };
  }

  String _patientLabel(Patient patient) {
    final details = [
      if (patient.registerId?.isNotEmpty == true) patient.registerId,
      if (patient.place.isNotEmpty) patient.place,
    ].whereType<String>().join(' • ');
    return details.isEmpty ? patient.name : '${patient.name} - $details';
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
