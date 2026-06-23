import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:oruma_app/models/medicine.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/models/medicine_supply.dart';
import 'package:oruma_app/services/medicine_service.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/services/medicine_supply_service.dart';
import 'package:oruma_app/services/auth_service.dart';

const _medicineDarkGreen = Color(0xFF0A4A3A);
const _medicineGreen = Color(0xFF0F6E56);
const _medicineSurface = Color(0xFFEBF4F1);
const _cardBg = Color(0xFFE1F5EE);
const _iconBg = Color(0xFF9FE1CB);

class MedicineSupplyPage extends StatefulWidget {
  final MedicineSupply? supply;

  const MedicineSupplyPage({super.key, this.supply});

  @override
  State<MedicineSupplyPage> createState() => _MedicineSupplyPageState();
}

class _MedicineSupplyPageState extends State<MedicineSupplyPage> {
  final _formKey = GlobalKey<FormState>();
  
  List<Patient> _patients = [];
  List<Medicine> _medicines = [];
  bool _loadingData = true;
  bool _saving = false;

  Patient? _selectedPatient;
  Medicine? _selectedMedicine;
  
  final TextEditingController _qtyController = TextEditingController();
  
  // Optional fields
  bool _showMore = false;
  String _status = 'given';
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _prescribedByController = TextEditingController();
  final TextEditingController _supplyDaysController = TextEditingController();
  
  DateTime _givenAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pResult = await PatientService.getAllPatients();
      final mResult = await MedicineService.getMedicines();
      
      if (mounted) {
        setState(() {
          _patients = pResult;
          _medicines = mResult;
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    _prescribedByController.dispose();
    _supplyDaysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a patient')));
      return;
    }
    if (_selectedMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a medicine')));
      return;
    }

    setState(() => _saving = true);

    try {
      final authService = context.read<AuthService>();
      final staffId = authService.user?['_id'] ?? authService.user?['id'];

      if (staffId == null) {
         throw Exception("You must be logged in to supply medicine.");
      }

      final supply = MedicineSupply(
        patientId: _selectedPatient!.id,
        medicineId: _selectedMedicine!.id!,
        givenByStaff: staffId,
        givenAt: _givenAt,
        qtyGiven: int.tryParse(_qtyController.text) ?? 0,
        status: _status,
        staffNote: _noteController.text.isEmpty ? null : _noteController.text,
        prescribedBy: _prescribedByController.text.isEmpty ? null : _prescribedByController.text,
        supplyDays: int.tryParse(_supplyDaysController.text),
      );

      await MedicineSupplyService.createMedicineSupply(supply);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine supplied successfully'),
            backgroundColor: _medicineDarkGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickGivenDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _givenAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _givenAt = date);
  }

  void _showMedicineDetails() {
    if (_selectedMedicine == null) return;
    final medicine = _selectedMedicine!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.medication, color: _medicineGreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medicine.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(medicine.code, style: const TextStyle(color: _medicineGreen, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Category', medicine.category.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')),
            _buildDetailRow('Formulation', medicine.formulation ?? 'Not set'),
            _buildDetailRow('Stock Available', '${medicine.qty} ${medicine.qtyUnit ?? ""}'),
            _buildDetailRow('Expiry Date', medicine.expiryDate != null ? DateFormat('dd MMM yyyy').format(medicine.expiryDate!) : 'Not set'),
            _buildDetailRow('Notes', medicine.description ?? 'None'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _medicineGreen),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _formIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_medicineDarkGreen, _medicineGreen],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.medication_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medicine Supply',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Supply medicine to a patient. Add optional details like supply days or notes if needed.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard({
    required String title,
    required String subtitle,
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
            color: _medicineDarkGreen.withValues(alpha: 0.06),
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
              Icon(icon, color: _medicineGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
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

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _medicineGreen, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FBFA),
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
        borderSide: const BorderSide(color: _medicineGreen, width: 1.5),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon, hint: hint),
      validator: required
          ? (value) =>
                value?.trim().isEmpty == true ? '$label is required' : null
          : null,
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _inputDecoration(
        label,
        Icons.arrow_drop_down_circle_outlined,
      ),
      items: values.map(
        (item) => DropdownMenuItem(
          value: item,
          child: Text(item.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')),
        ),
      ).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5FAF8),
        appBar: AppBar(
          backgroundColor: _medicineDarkGreen,
          foregroundColor: Colors.white,
          title: const Text('New Supply', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: const Center(child: CircularProgressIndicator(color: _medicineGreen)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF8),
      appBar: AppBar(
        backgroundColor: _medicineDarkGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'New Supply',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: [
            _formIntro(),
            const SizedBox(height: 16),
            _formCard(
              title: 'Supply details',
              subtitle: 'Patient and medicine information.',
              icon: Icons.person_add_alt_1_outlined,
              children: [
                Autocomplete<Patient>(
                  displayStringForOption: (option) => '${option.name} (${option.phone})',
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<Patient>.empty();
                    return _patients.where((p) => p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (selection) => setState(() => _selectedPatient = selection),
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: _inputDecoration(
                        'Patient',
                        Icons.person_search_outlined,
                        hint: 'Search patient...',
                      ),
                      validator: (value) => _selectedPatient == null ? 'Please select a patient' : null,
                    );
                  },
                ),
                if (_selectedPatient != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _iconBg),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: _medicineGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedPatient!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: _medicineDarkGreen),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _selectedPatient = null),
                          child: const Icon(Icons.close, color: _medicineGreen, size: 20),
                        ),
                      ],
                    ),
                  ),

                Autocomplete<Medicine>(
                  displayStringForOption: (option) => option.name,
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<Medicine>.empty();
                    return _medicines.where((m) => m.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (selection) => setState(() => _selectedMedicine = selection),
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: _inputDecoration(
                        'Medicine',
                        Icons.medication_outlined,
                        hint: 'Search medicine...',
                      ),
                      validator: (value) => _selectedMedicine == null ? 'Please select a medicine' : null,
                    );
                  },
                ),
                
                if (_selectedMedicine != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _iconBg),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medication_liquid, color: _medicineGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedMedicine!.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: _medicineDarkGreen),
                              ),
                              Text(
                                'Stock: ${_selectedMedicine!.qty}',
                                style: TextStyle(color: _medicineDarkGreen.withValues(alpha: 0.8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _showMedicineDetails,
                          child: const Icon(Icons.info_outline, color: _medicineGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => setState(() => _selectedMedicine = null),
                          child: const Icon(Icons.close, color: _medicineGreen, size: 20),
                        ),
                      ],
                    ),
                  ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _textField(
                        _qtyController,
                        'Quantity',
                        hint: 'e.g. 10',
                        icon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: _pickGivenDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            'Date',
                            Icons.event_outlined,
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_givenAt),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => setState(() => _showMore = !_showMore),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _medicineSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_outlined, color: _medicineDarkGreen),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'More details',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _medicineDarkGreen,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Status, prescribed by, supply days, and notes',
                            style: TextStyle(
                              color: Color(0xFF5F786F),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showMore ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _medicineDarkGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _formCard(
                  title: 'Optional details',
                  subtitle: 'Extra information for this supply.',
                  icon: Icons.fact_check_outlined,
                  children: [

                    _textField(
                      _prescribedByController,
                      'Prescribed By',
                      hint: 'Doctor name',
                      icon: Icons.medical_information_outlined,
                    ),
                    _textField(
                      _supplyDaysController,
                      'Supply Days',
                      hint: 'How many days this stock should last',
                      icon: Icons.calendar_month_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    _textField(
                      _noteController,
                      'Staff Note',
                      hint: 'Internal remarks...',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              crossFadeState: _showMore
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 260),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          color: Colors.white,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _medicineGreen,
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
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Supply Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
